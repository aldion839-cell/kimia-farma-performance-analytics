# Analisis Kimia Farma 2020–2023

Status: empat CSV berhasil diimpor dan `kf_analisis_final` berhasil dibuat di BigQuery. Semua tujuh pemeriksaan ASSERT lulus pada 25 September 2026. Project: `intership-project-kimia-farma`, dataset: `kimia_farma`, lokasi: US. Dashboard dan bahan presentasi sedang disusun. Repository ini menyimpan SQL dan dokumentasi analisis.

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
5. Kedua file SQL sudah memakai Project ID `intership-project-kimia-farma`.
6. Jalankan `01_tabel_analisis.sql`, lalu query pada `02_analisis_dashboard.sql`. Script pertama memakai CREATE TABLE dan akan berhenti bila `kf_analisis_final` sudah ada, agar hasil lama tidak tertimpa.

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

Angka berikut dihitung dari CSV dengan Python, belum merupakan hasil eksekusi BigQuery. Cocokkan total setelah SQL dijalankan.

| Tahun | Transaksi | Nett sales (Rp) | Estimasi profit (Rp) |
|---|---:|---:|---:|
| 2020 | 168.651 | 80.437.605.040 | 22.842.355.149,65 |
| 2021 | 167.697 | 80.037.846.824 | 22.731.171.469,50 |
| 2022 | 168.642 | 80.578.445.844 | 22.883.598.882,80 |
| 2023 | 167.468 | 80.117.292.611 | 22.757.862.557,90 |

## Rancangan Looker Studio

Hubungkan tabel `kf_analisis_final` menggunakan konektor BigQuery. Judul: Kinerja Bisnis Kimia Farma 2020–2023. Gunakan kontrol rentang tanggal, provinsi, dan kategori cabang.

- Scorecard: COUNT_DISTINCT(transaction_id), SUM(nett_sales), SUM(nett_profit), AVG(rating_transaksi).
- Grafik kolom pendapatan menurut tahun, dengan nett_sales dijumlahkan.
- Dua grafik batang Top 10 provinsi: jumlah transaksi dan nett sales.
- Tabel Top 5 cabang: branch_id, branch_name, kota, rating cabang (MAX), rating transaksi (AVG), dan jumlah transaksi. Urutan mengikuti metode di atas.
- Peta Indonesia: provinsi sebagai wilayah dan SUM(nett_profit). Periksa pengenalan nama provinsi; jangan menghilangkan wilayah yang gagal dikenali tanpa catatan.
- Snapshot tabel transaksi: tanggal, ID, cabang, produk, nett sales, nett profit. Hindari menampilkan nama pelanggan pada dashboard publik.
- Tambahkan catatan asumsi profit dan batas tanggal data. Semua grafik harus merespons filter yang sama.

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

Job BigQuery berhasil: `job_Wm7sS0fD5y1DoQPuFa94z_0Mion9` (US), delapan statement sukses termasuk tujuh ASSERT. Dashboard dalam pengerjaan: https://datastudio.google.com/reporting/35ecf4ad-c21a-4a19-8b89-c035c303c1bf

