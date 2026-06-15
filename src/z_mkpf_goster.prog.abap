REPORT z_mkpf_goster.

*&---------------------------------------------------------------------*
*& Program Tanımı: MKPF tablosundan ilk 10 kaydı çeker ve ALV'de gösterir.
*&---------------------------------------------------------------------*

* Dahili tablo ve çalışma alanı tanımlamaları
DATA: gt_mkpf TYPE TABLE OF mkpf, " MKPF verilerini tutacak dahili tablo
      gs_mkpf TYPE mkpf.          " MKPF çalışma alanı

* ALV için gerekli değişkenler
DATA: gt_fieldcat TYPE lvc_t_fcat, " Alan kataloğu tablosu
      gs_layout   TYPE lvc_s_layo. " ALV layout yapısı

START-OF-SELECTION.
* MKPF tablosundan ilk 10 kaydı seç
  SELECT *
    FROM mkpf
    INTO TABLE gt_mkpf
    UP TO 10 ROWS.

* Seçim başarılı ise ALV'yi göster
  IF sy-subrc EQ 0.
* ALV layout ayarları (isteğe bağlı)
    gs_layout-zebra = 'X'. " Satırları farklı renklerde göster
    gs_layout-col_opt = 'X'. " Kolon genişliğini otomatik ayarla

* ALV fonksiyon modülünü çağır
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
      EXPORTING
        i_callback_program = sy-repid      " Geri çağrı programı
        i_structure_name   = 'MKPF'        " Referans yapı adı
        is_layout_lvc      = gs_layout     " ALV layout ayarları
      TABLES
        it_outtab          = gt_mkpf       " Görüntülenecek veri tablosu
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
* Hata durumunda mesaj göster
      MESSAGE 'ALV görüntülenirken bir hata oluştu.' TYPE 'E'.
    ENDIF.
  ELSE.
* Kayıt bulunamadı mesajı
    MESSAGE 'MKPF tablosunda kayıt bulunamadı.' TYPE 'I'.
  ENDIF.