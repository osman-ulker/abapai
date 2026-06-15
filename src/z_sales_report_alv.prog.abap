```abap
REPORT z_sales_report_alv.

*&---------------------------------------------------------------------*
*& Program Tanımı: Satış Siparişleri ALV Raporu
*&                 Seçim ekranı ile satış siparişlerini filtreler ve
*&                 sonuçları ALV grid olarak görüntüler.
*&                 ALV çıktısı Excel'e aktarılabilir.
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Tablolar
*&---------------------------------------------------------------------*
TABLES: vbak. " Satış Belgesi Başlık Verileri

*&---------------------------------------------------------------------*
*& Seçim Ekranı Tanımlamaları
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001. " Seçim Kriterleri
  SELECT-OPTIONS: s_vbeln FOR vbak-vbeln NO INTERVALS, " Satış Belgesi Numarası
                  s_kunnr FOR vbak-kunnr,             " Müşteri Numarası
                  s_erdat FOR vbak-erdat.             " Oluşturma Tarihi
SELECTION-SCREEN END OF BLOCK b1.

*&---------------------------------------------------------------------*
*& Veri Tanımlamaları
*&---------------------------------------------------------------------*
* ALV için nihai iç tablo yapısı
TYPES: BEGIN OF ty_sales_data,
         vbeln TYPE vbak-vbeln, " Satış Belgesi Numarası
         erdat TYPE vbak-erdat, " Oluşturma Tarihi
         kunnr TYPE vbak-kunnr, " Müşteri Numarası
         netwr TYPE vbap-netwr, " Net Değer
         waerk TYPE vbap-waerk, " Para Birimi
       END OF ty_sales_data.

DATA: lt_vbak       TYPE STANDARD TABLE OF vbak,          " VBAK verilerini tutmak için
      lt_vbap       TYPE STANDARD TABLE OF vbap,          " VBAP verilerini tutmak için
      lt_sales_data TYPE STANDARD TABLE OF ty_sales_data, " ALV için nihai veri tablosu
      ls_sales_data TYPE ty_sales_data.                   " ALV için nihai veri çalışma alanı

* ALV için field catalog ve layout yapıları
DATA: lt_fieldcat TYPE lvc_t_fcat, " ALV field catalog tablosu
      ls_layout   TYPE lvc_s_layo. " ALV layout yapısı

*&---------------------------------------------------------------------*
*& Başlangıç Olayı
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM get_data.
  PERFORM prepare_alv_data.
  PERFORM display_alv.

*&---------------------------------------------------------------------*
*& Form Rutinleri
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& FORM GET_DATA
*& Veritabanından satış siparişi verilerini çeker.
*&---------------------------------------------------------------------*
FORM get_data.
* VBAK tablosundan başlık verilerini çek
  SELECT vbeln, erdat, kunnr
    FROM vbak
    INTO TABLE lt_vbak
    WHERE vbeln IN s_vbeln
      AND kunnr IN s_kunnr