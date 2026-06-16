REPORT z_oo_alv_vbak_top10.

*----------------------------------------------------------------------*
* ABAP Program: Z_OO_ALV_VBAK_TOP10
* Açıklama: VBAK tablosundan ilk 10 kaydı çeken ve nesne yönelimli (OO)
*          yaklaşımla ALV grid üzerinde listeleyen profesyonel bir rapor.
*          ALV gösterimi için yerel bir sınıf kullanır.
*----------------------------------------------------------------------*

* ALV için gerekli tip havuzları (SLIS, LVC)
TYPE-POOLS: slis, lvc.

*----------------------------------------------------------------------*
* Global Veri Tanımlamaları
*----------------------------------------------------------------------*
DATA:
  gt_vbak TYPE TABLE OF vbak, " VBAK verilerini tutacak dahili tablo
  go_alv_handler TYPE REF TO lcl_alv_handler. " ALV işleyici sınıfının referansı

*----------------------------------------------------------------------*
* Ekran Elemanları Tanımlamaları
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF SCREEN 900 AS WINDOW TITLE TEXT-001.
* ALV grid'in yerleştirileceği custom container için bir alan
* Bu alan, ekran üzerinde ALV'nin görüneceği yerdir.
  CLASS cl_gui_custom_container DEFINITION LOAD.
  CLASS cl_gui_alv_grid DEFINITION LOAD.
  CONTAINER alv_container_0100 FOR ETCHING FIELD 'ALV_TITLE'.
  DATA: alv_title TYPE string VALUE 'VBAK İlk 10 Kayıt'.
SELECTION-SCREEN END OF SCREEN 900.

*----------------------------------------------------------------------*
* Yerel Sınıf Tanımlaması: LCL_ALV_HANDLER
* ALV grid'in oluşturulması, veri gösterimi ve olay yönetimi gibi
* tüm ALV ile ilgili mantığı kapsar.
*----------------------------------------------------------------------*
CLASS lcl_alv_handler DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          iv_container_name TYPE scrfname, " ALV'nin yerleşeceği container adı
      display_data
        IMPORTING
          it_data TYPE ANY TABLE, " ALV'de gösterilecek veri tablosu
      handle_double_click FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no,
      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no.

  PRIVATE SECTION.
    DATA:
      mo_container TYPE REF TO cl_gui_custom_container, " Custom container referansı
      mo_alv_grid  TYPE REF TO cl_gui_alv_grid,         " ALV grid referansı
      mt_fieldcat  TYPE lvc_t_fcat.                     " Alan kataloğu tablosu

    METHODS:
      build_field_catalog
        IMPORTING
          it_data TYPE ANY TABLE, " Alan kataloğu oluşturulacak veri tablosu
        RAISING
          cx_salv_msg,            " Hata durumunda fırlatılacak istisna
      create_alv_grid
        RAISING
          cx_salv_msg,            " Hata durumunda fırlatılacak istisna
      register_events.            " ALV olaylarını kaydetme metodu
ENDCLASS.

*----------------------------------------------------------------------*
* Yerel Sınıf Uygulaması: LCL_ALV_HANDLER
*----------------------------------------------------------------------*
CLASS lcl_alv_handler IMPLEMENTATION.

  METHOD constructor.
* Custom container'ı oluştur
    CREATE OBJECT mo_container
      EXPORTING
        container_name = iv_container_name
      EXCEPTIONS
        cntl_error     = 1
        cntl_system_error = 2
        create_error   = 3
        lifetime_error = 4
        lifetime_dyn_error = 5
        OTHERS         = 6.
    IF sy-subrc <> 0.
      MESSAGE 'ALV container oluşturulurken hata oluştu.' TYPE 'E'.
      RAISE EXCEPTION TYPE cx_salv_msg. " Daha spesifik bir istisna fırlatılabilir
    ENDIF.

* ALV grid'i oluştur
    CREATE OBJECT mo_alv_grid
      EXPORTING
        i_parent = mo_container
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
      MESSAGE 'ALV grid oluşturulurken hata oluştu.' TYPE 'E'.
      RAISE EXCEPTION TYPE cx_salv_msg.
    ENDIF.

* ALV olaylarını kaydet
    me->register_events( ).

  ENDMETHOD.

  METHOD display_data.
* Alan kataloğunu oluştur
    me->build_field_catalog( it_data = it_data ).

* ALV'yi ilk kez göster
    CALL METHOD mo_alv_grid->set_table_for_first_display
      EXPORTING
        is_variant          = VALUE #( report = sy-repid ) " Varyant yönetimi için
        i_save              = 'A'                         " Varyantları kaydetme yetkisi
        i_default           = 'X'                         " Varsayılan varyantı kullan
        is_layout           = VALUE #( zebra = 'X' )       " Zebra deseni
      CHANGING
        it_outtab           = it_data                     " Gösterilecek veri tablosu
        it_fieldcatalog     = mt_fieldcat                 " Alan kataloğu
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
      MESSAGE 'ALV gösterilirken hata oluştu.' TYPE 'E'.
    ENDIF.

* Ekranı yenile
    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        cntl_system_error = 1
        cntl_error        = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE 'Ekran yenilenirken hata oluştu.' TYPE 'E'.
    ENDIF.

  ENDMETHOD.

  METHOD build_field_catalog.
    DATA:
      ls_fieldcat TYPE lvc_s_fcat,
      lt_ddic_fields TYPE TABLE OF dfies,
      ls_ddic_field TYPE dfies.

* Dahili tablonun yapısını al
    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = cl_abap_structdescr=>get_by_data( it_data )->get_relative_name( )
        langu          = sy-langu
      TABLES
        dfies_tab      = lt_ddic_fields
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      MESSAGE 'Alan kataloğu oluşturulurken DDIC bilgisi alınamadı.' TYPE 'E'.
      RAISE EXCEPTION TYPE cx_salv_msg.
    ENDIF.

    CLEAR mt_fieldcat.
    LOOP AT lt_ddic_fields INTO ls_ddic_field.
      CLEAR ls_fieldcat.
      ls_fieldcat-fieldname = ls_ddic_field-fieldname.
      ls_fieldcat-coltext   = ls_ddic_field-fieldtext. " Alan metni
      ls_fieldcat-scrtext_s = ls_ddic_field-scrtext_s. " Kısa ekran metni
      ls_fieldcat-scrtext_m = ls_ddic_field-scrtext_m. " Orta ekran metni
      ls_fieldcat-scrtext_l = ls_ddic_field-scrtext_l. " Uzun ekran metni
      ls_fieldcat-outputlen = ls_ddic_field-outputlen. " Çıkış uzunluğu

* Örnek: Belirli alanları hotspot yapma
      IF ls_fieldcat-fieldname = 'VBELN'.
        ls_fieldcat-hotspot = 'X'.
      ENDIF.

      APPEND ls_fieldcat TO mt_fieldcat.
    ENDLOOP.
  ENDMETHOD.

  METHOD register_events.
* Double click olayını kaydet
    SET HANDLER me->handle_double_click FOR mo_alv_grid.
* Hotspot click olayını kaydet
    SET HANDLER me->handle_hotspot_click FOR mo_alv_grid.
* Diğer olaylar da burada kaydedilebilir (örn: data_changed_finished)
  ENDMETHOD.

  METHOD handle_double_click.
* Çift tıklama olayını işleme
    MESSAGE i000(00) WITH 'Çift tıklandı:' e_row_id-index 'satırında,' e_column_id-fieldname 'alanında.'.
  ENDMETHOD.

  METHOD handle_hotspot_click.
* Hotspot tıklama olayını işleme
    MESSAGE i000(00) WITH 'Hotspot tıklandı:' e_row_id-index 'satırında,' e_column_id-fieldname 'alanında.'.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Programın Başlangıcı
*----------------------------------------------------------------------*
INITIALIZATION.
* Metin sembollerini yükle
  TEXT-001 = 'VBAK İlk 10 Kayıt ALV Raporu'.

START-OF-SELECTION.
* VBAK tablosundan ilk 10 kaydı çek
  SELECT *
    FROM vbak
    INTO TABLE gt_vbak
    UP TO 10 ROWS.

  IF sy-subrc <> 0.
    MESSAGE 'VBAK tablosundan veri çekilemedi.' TYPE 'E'.
    RETURN.
  ENDIF.

* ALV işleyici sınıfını oluştur
  TRY.
      CREATE OBJECT go_alv_handler
        EXPORTING
          iv_container_name = 'ALV_CONTAINER_0100'. " Ekrandaki container adı
    CATCH cx_salv_msg.
      MESSAGE 'ALV işleyici oluşturulurken hata oluştu.' TYPE 'E'.
      RETURN.
  ENDTRY.

* ALV'yi göster
  go_alv_handler->display_data( it_data = gt_vbak ).

END-OF-SELECTION.
* ALV'nin gösterileceği ekranı çağır
  CALL SCREEN 900.

*----------------------------------------------------------------------*
* PBO (Process Before Output) ve PAI (Process After Input) Modülleri
*----------------------------------------------------------------------*
MODULE status_900 OUTPUT.
  SET PF-STATUS 'STANDARD_FULLSCREEN'. " Standart tam ekran PF-STATUS
  SET TITLEBAR 'TITLE_900'.            " Başlık çubuğu
ENDMODULE.

MODULE user_command_900 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.

*----------------------------------------------------------------------*
* Başlık Çubuğu Tanımlaması
*----------------------------------------------------------------------*
* TITLE_900 başlık çubuğunu oluşturun ve metnini 'VBAK İlk 10 Kayıt' olarak ayarlayın.
* PF-STATUS STANDARD_FULLSCREEN'i oluşturun ve BACK, EXIT, CANCEL fonksiyon kodlarını
* uygun butonlara atayın.
*----------------------------------------------------------------------*