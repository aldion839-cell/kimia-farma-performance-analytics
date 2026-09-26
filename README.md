# Analisis Kimia Farma 2020–2023

Status: empat CSV berhasil diimpor dan `kf_analisis_final` berhasil dibuat di BigQuery. Semua tujuh pemeriksaan ASSERT lulus pada 25 September 2026. Project: `intership-project-kimia-farma`, dataset: `kimia_farma`, lokasi: US. Dashboard enam halaman sudah dibuat. Repository ini menyimpan SQL dan dokumentasi analisis; presentasi dan naskah pembicara disimpan terpisah.

## Hasil pemeriksaan sumber

| Dataset | Baris |
|---|---:|
| kf_final_transaction | 672.458 |
| kf_inventory | 1.035.000 |
| kf_kantor_cabang | 1.725 |
| kf_product | 150 |

Tidak ditemukan nilai kosong, duplikasi baris lengkap, atau duplikasi ID utama pada keempat file. Semua transaksi memiliki master cabang dan produk. Harga transaksi sama dengan harga master produk. Tanggal memakai bulan/hari/tahun, dengan rentang 1 Januari 2020–30 Desember 2023. Diskon berbentuk pecahan 0–0,15; jangan dibagi 100 lagi.

Inventory memiliki 780.996 baris tambahan pada pasangan branch_id/product_id yang berulang. Karena itu, join langsung akan menggandakan transaksi. SQL merangkum inventory menjadi satu baris per pasangan sebelum LEFT JOIN. Sebanyak 12.336 transaksi tidak memiliki pasangan inventory, tetapi tetap dihitung. Ketiadaan pasangan bukan bukti kehabisan stok. Inventory tidak memiliki tanggal, sehingga tidak digunakan untuk menyimpulkan stok historis.

## Impor ke BigQuery

1. Buka project yang benar dan buat dataset `kimia_farma` jika belum tersedia. Pertahankan lokasi dataset yang sudah dipilih.
2. Impor setiap CSV dengan nama tabel yang sama dengan nama file tanpa `.csv`. Sumber file tersedia pada tautan di bawah.
3. Pilih CSV, header 1 baris, delimiter koma, quote tanda petik ganda. Gunakan schema eksplisit berikut sesuai urutan kolom CSV.
4. Gunakan `date` bertipe STRING pada tabel transaksi agar tanggal bulan/hari/tahun diproses secara eksplisit oleh SQL.
5. Ketiga file SQL sudah memakai Project ID `intership-project-kimia-farma`.
6. Jalankan `01_tabel_analisis.sql`, lalu query pada `02_analisis_dashboard.sql` dan `03_insight_farmasi.sql`. Script pertama memakai CREATE TABLE dan akan berhenti bila `kf_analisis_final` sudah ada, agar hasil lama tidak tertimpa.

Schema (format Edit as text pada form pembuatan tabel):

```
kf_final_transaction:
transaction_id:STRING,date:STRING,branch_id:INTEGER,customer_name:STRING,product_id:STRING,price:NUMERIC,discount_percentage:NUMERIC,rating:NUMERIC

kf_inventory:
Inventory_ID:STRING,branch_id:INTEGER,product_id:STRING,product_name:STRING,opname_stock:INTEGER

kf_kantor_cabang:
branch_id:INTEGER,branch_category:STRING,branch_name:STRING,kota:STRING,provinsi:STRING,rating:NUMERIC

kf_product:
product_id:STRING,product_name:STRING,product_category:STRING,price:NUMERIC
```

Hanya salin baris schema, tanpa nama tabel di atasnya. Jangan mengaktifkan append saat mengulang impor pada tabel yang sudah berisi data.

## Metode

Satu baris analisis = satu transaksi. Harga transaksi dipakai sebagai actual_price. Nett sales = harga × (1 − diskon). Tarif laba ditetapkan dari harga sebelum diskon sesuai interval panduan. Nett profit = nett sales × tarif laba, sebagai asumsi analisis tugas. Ini estimasi profit, bukan laba bersih akuntansi: HPP, biaya operasi, dan pajak tidak tersedia.

Top 5 cabang diurutkan berdasarkan rating cabang menurun, lalu rata-rata rating transaksi menaik, kemudian branch_id. Nama cabang berulang, jadi branch_id harus ikut menjadi dimensi.

## Angka kontrol lokal

Angka tahunan berikut dihitung ulang dari CSV sebagai kontrol analisis. Total baris dan nett sales direkonsiliasi oleh ASSERT BigQuery. Total seluruh periode: 672.458 transaksi, nett sales Rp321.171.190.319, dan estimasi profit Rp91.214.988.059,85.

| Tahun | Transaksi | Nett sales (Rp) | Estimasi profit (Rp) |
|---|---:|---:|---:|
| 2020 | 168.651 | 80.437.605.040 | 22.842.355.149,65 |
| 2021 | 167.697 | 80.037.846.824 | 22.731.171.469,50 |
| 2022 | 168.642 | 80.578.445.844 | 22.883.598.882,80 |
| 2023 | 167.468 | 80.117.292.611 | 22.757.862.557,90 |

## Dashboard

[Buka dashboard Kinerja Bisnis Kimia Farma 2020–2023](https://datastudio.google.com/reporting/203c39a7-638c-4fd9-ad4b-26bea3ecaf0e)

Sumber dashboard adalah tabel BigQuery `kf_analisis_final`. Filter tanggal dan provinsi tersedia pada tingkat laporan.

1. **Ringkasan Kinerja:** total transaksi, nett sales, estimasi profit, dan pendapatan per tahun.
2. **Kinerja Provinsi:** Top 10 provinsi berdasarkan jumlah transaksi dan nett sales.
3. **Persebaran Profit:** peta Indonesia berdasarkan estimasi profit provinsi.
4. **Rating Cabang:** Top 5 cabang berdasarkan rating cabang tertinggi, lalu rata-rata rating transaksi terendah; ditampilkan ID cabang, kota, jumlah transaksi, dan kedua rating.
5. **Snapshot Data:** ID transaksi, tanggal, ID cabang, ID produk, nett sales, dan estimasi profit. Nama pelanggan tidak ditampilkan.
6. **Insight Farmasi:** narasi statis untuk keseluruhan periode 2020–2023, sehingga angka pada halaman ini tidak berubah mengikuti filter.

## Insight bisnis farmasi

Temuan ini berlaku untuk dataset latihan, bukan laporan keuangan atau gambaran operasional aktual perusahaan.

| Temuan | Implikasi dan tindak lanjut |
|---|---|
| Sales 2023 turun sekitar 0,57% dibanding 2022 | Periksa pola bulanan dan komposisi produk sebelum menyimpulkan penyebab. |
| Jawa Barat menghasilkan Rp94,87 miliar atau 29,54% sales, dengan 510 cabang | Prioritaskan kapasitas layanan wilayah besar, tetapi bandingkan produktivitas per cabang. |
| Sales per cabang selama empat tahun: Jawa Barat Rp186,02 juta; Kalimantan Selatan Rp189,62 juta | Kalimantan Selatan sekitar 1,94% lebih tinggi; belum disesuaikan hari aktif, sehingga tidak cukup sebagai dasar ekspansi. |
| Kode kategori R06 menghasilkan Rp64,86 miliar atau 20,20% sales; tiga kategori teratas menyumbang 53,34% | Validasi kecocokan kode dan nama produk sebelum menafsirkan kelas terapi atau menetapkan assortment. |
| Diskon Rp26,05 miliar, sekitar 7,50% dari nilai sebelum diskon | Evaluasi promosi membutuhkan kelompok pembanding, unit terjual, dan biaya aktual; angka ini tidak membuktikan efek kausal diskon. |
| Cabang 82157 di Tarakan memiliki rating cabang 5 dan rata-rata rating transaksi 3,905 | Tinjau proses layanan dan umpan balik transaksi; selisih rating belum menjelaskan penyebab. |

Untuk analisis operasional farmasi lanjutan, tambahkan unit terjual, batch, tanggal kedaluwarsa, stok per tanggal, dan lead time pengadaan. Data saat ini belum dapat membuktikan stockout, kehilangan penjualan, atau kerugian akibat kedaluwarsa.

## Sumber

- [Panduan Rakamin](https://rakamin-lms.s3.ap-southeast-1.amazonaws.com/files/Kimia_Farma__Big_Data_Analyst__Challenge_Prerequisite_and_Hints__Final_Task-9902254e-5c2e-40b2-b42c-7a20cb46c562.pdf)
- [Transaksi](https://drive.google.com/file/d/1iDOBdKZ4-kkLhpklQWWrsFvACtI7MCz3/view)
- [Inventory](https://drive.google.com/file/d/1ihtG2t0V1AO0IAGkGwQaqtba6AxDEKDI/view)
- [Kantor cabang](https://drive.google.com/file/d/1vzaasqIeXqqe_jI99dNLaa8nxnoe9OWW/view)
- [Produk](https://drive.google.com/file/d/1739wO7BwtVStHCA4Dcj9xGhlc_blBNbT/view)
- [Dokumentasi impor BigQuery](https://docs.cloud.google.com/bigquery/docs/batch-loading-data)
- [Dokumentasi PARSE_DATE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/date_functions)

## Kompatibilitas Sandbox

Project memakai BigQuery Sandbox. Tabel analisis dibuat tanpa partisi tanggal karena Sandbox memberikan masa kedaluwarsa partisi 60 hari, yang mengosongkan partisi historis 2020–2023. Tabel percobaan `kf_analisis` kosong; tabel final yang digunakan adalah `kf_analisis_final`. Empat tabel sumber tidak diubah. Tabel Sandbox juga memiliki masa berlaku otomatis; simpan sumber dan SQL untuk reproduksi sebelum kedaluwarsa.

## Bukti eksekusi

Job BigQuery berhasil: `job_Wm7sS0fD5y1DoQPuFa94z_0Mion9` (US), delapan statement sukses termasuk tujuh ASSERT. Dashboard: [Kinerja Bisnis Kimia Farma 2020–2023](https://datastudio.google.com/reporting/203c39a7-638c-4fd9-ad4b-26bea3ecaf0e).

