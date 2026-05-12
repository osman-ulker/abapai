REPORT zekko_alv_report.

* EKKO tablosundan veri cekmek icin dahili tablo tanimlamasi
DATA: lt_ekko TYPE TABLE OF ekko.

* Veritabanindan ilk 10 kaydi sec
SELECT * FROM ekko INTO TABLE lt_ekko UP TO 10 ROWS.

* Veri bulunduysa ALV gosterimini baslat
IF lt_ekko IS NOT INITIAL.
  TRY.
* SALV factory metodunu kullanarak nesne olustur
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = DATA(lo_alv)
        CHANGING
          t_table      = lt_ekko
      ).

* ALV fonksiyonlarini (siralama, filtreleme vb.) aktif et
      DATA(lo_functions) = lo_alv->get_functions( ).
      lo_functions->set_all( abap_true ).

* ALV ekranini goruntule
      lo_alv->display( ).

    CATCH cx_salv_msg.
* Hata yonetimi buraya eklenebilir
  ENDTRY.
ELSE.
* Kayit bulunamadiysa mesaj ver
  MESSAGE 'Veri bulunamadi.' TYPE 'I'.
ENDIF.