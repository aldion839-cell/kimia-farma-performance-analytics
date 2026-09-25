-- Analisis bisnis farmasi. Angka berlaku untuk dataset tugas, bukan laporan perusahaan.
-- Komposisi kategori: gunakan kode asli sampai klasifikasi produk tervalidasi.
WITH kategori AS (
 SELECT product_category, COUNT(*) AS transaksi, SUM(nett_sales) AS nett_sales,
 SUM(nett_profit) AS estimasi_profit
 FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`
 GROUP BY product_category
)
SELECT *, SAFE_DIVIDE(nett_sales,SUM(nett_sales) OVER()) AS kontribusi_sales
FROM kategori ORDER BY nett_sales DESC;

-- Produktivitas per cabang selama seluruh periode, belum disesuaikan hari aktif.
SELECT provinsi, COUNT(DISTINCT branch_id) AS cabang_bertransaksi,
 SUM(nett_sales) AS nett_sales,
 SAFE_DIVIDE(SUM(nett_sales),COUNT(DISTINCT branch_id)) AS sales_per_cabang
FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`
GROUP BY provinsi ORDER BY sales_per_cabang DESC;

-- Nilai diskon tertimbang harga. Analisis deskriptif, bukan efek kausal promosi.
SELECT SUM(actual_price) AS nilai_sebelum_diskon,
 SUM(actual_price * discount_percentage) AS nilai_diskon,
 SAFE_DIVIDE(SUM(actual_price * discount_percentage),SUM(actual_price)) AS diskon_tertimbang,
 SUM(nett_sales) AS nett_sales, AVG(nett_sales) AS rata_nilai_transaksi
FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`;

-- Pemeriksaan klasifikasi: tinjau kecocokan nama dengan kategori secara manual.
SELECT product_category, COUNT(DISTINCT product_name) AS variasi_nama,
 ARRAY_AGG(DISTINCT product_name ORDER BY product_name) AS nama_produk
FROM `intership-project-kimia-farma.kimia_farma.kf_product`
GROUP BY product_category;
