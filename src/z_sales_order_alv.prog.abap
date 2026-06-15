REPORT z_sales_order_alv.

*----------------------------------------------------------------------*
* SEÇİM EKRANI TANIMLAMALARI                                           *
*----------------------------------------------------------------------*
* Satış Belgesi Numarası için seçim aralığı
SELECT-OPTIONS s_vbeln FOR vbak-vbeln.
* Müşteri Numarası için seçim aralığı
SELECT-OPTIONS s_kunnr FOR vbak-kunnr.
* Oluşturma Tarihi için seçim aralığı
SELECT-OPTIONS s_erdat FOR vbak-erdat.

*----------------------------------------------------------------------*
* VERİ YAPILARI TANIMLAMALARI                                          *
*----------------------------------------------------------------------*
* ALV ekranında gösterilecek veriler için bir yapı tanımlaması
TYPES: BEGIN OF ty_sales_data,
         vbeln TYPE vbak-vbeln, " Satış Belgesi Numarası
         erdat TYPE vbak-erdat, " Oluşturma Tarihi
         kunnr TYPE vbak-kunnr, " Müşteri Numarası
         netwr TYPE vbak-netwr, " Net Değer
         waerk TYPE vbak-waerk, " Para Birimi
       END OF ty_sales_data.

* ALV verilerini tutacak dahili tablo
DATA gt_sales_data TYPE TABLE OF ty_sales_data.

* ALV objesi için referans
DATA gr_salv_table TYPE REF TO cl_salv_table.

*----------------------------------------------------------------------*
* PROGRAM BAŞLANGICI                                                   *
*----------------------------------------------------------------------*
START-OF-SELECTION.
* VBAK tablosundan satış siparişi başlık verilerini çek
  SELECT vbeln, erdat, kunnr, netwr, waerk
    FROM vbak
    INTO TABLE @gt_sales_data
    WHERE vbeln IN @s_vbeln
      AND kunnr IN @s_kunnr
      AND erdat IN @s_erdat.

* Eğer veri bulunamazsa kullanıcıya mesaj göster
  IF gt_sales_data IS INITIAL.
    MESSAGE 'Belirtilen kriterlere uygun satış siparişi bulunamadı.' TYPE 'I'.
    EXIT.
  ENDIF.

END-OF-SELECTION.
* ALV görüntüsünü oluştur ve göster
  PERFORM display_alv.

*----------------------------------------------------------------------*
* ALV GÖRÜNTÜLEME ALT PROGRAMI                                        *
*----------------------------------------------------------------------*
FORM display_alv.
  TRY.
* CL_SALV_TABLE sınıfını kullanarak ALV objesini oluştur
      cl_salv_table=>factory(
        EXPORTING
          r_container = space    " ALV'yi tam ekran göster
        IMPORTING
          r_salv_table = gr_salv_table
        CHANGING
          t_table      = gt_sales_data
      ).

* ALV başlığını ayarla
      DATA(lo_display_settings) = gr_salv_table->get_display_settings( ).
      lo_display_settings->set_list_header( 'Satış Siparişi Listesi' ).

* ALV'yi göster
      gr_salv_table->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv_msg).
* Hata durumunda mesajı göster
      MESSAGE lx_salv_msg->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.