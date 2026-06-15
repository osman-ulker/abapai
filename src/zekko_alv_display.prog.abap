REPORT zekko_alv_display.

* EKKO tablosundan çekilecek verileri tutmak için dahili tablo
DATA: gt_ekko TYPE TABLE OF ekko.

* ALV layout ayarları için yapı
DATA: gs_layout TYPE slis_layout_alv.

START-OF-SELECTION.
* EKKO tablosundan ilk 10 kaydı seç ve gt_ekko dahili tablosuna aktar
  SELECT *
    FROM ekko
    INTO TABLE @gt_ekko
    UP TO 10 ROWS.

* ALV layout ayarlarını yap
  gs_layout-zebra = 'X'. " Satırlara zebra deseni uygula
  gs_layout-colwidth_optimize = 'X'. " Sütun genişliklerini otomatik ayarla

* ALV gridini görüntüle
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid         " Geri çağrı programının adı
      i_structure_name   = 'EKKO'           " Veri yapısının adı (EKKO tablosu)
      is_layout          = gs_layout        " ALV layout ayarları
    TABLES
      t_outtab           = gt_ekko          " Görüntülenecek veri tablosu
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
* ALV görüntülenirken bir hata oluşursa mesaj göster
    MESSAGE 'ALV görüntülenirken bir hata oluştu.' TYPE 'E'.
  ENDIF.