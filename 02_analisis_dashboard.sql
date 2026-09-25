-- Project: intership-project-kimia-farma. Jalankan setiap query secara terpisah untuk melihat hasilnya.

-- KPI keseluruhan
SELECT COUNT(DISTINCT transaction_id) AS total_transaksi,
  COUNT(DISTINCT branch_id) AS total_cabang,
  SUM(nett_sales) AS total_nett_sales, SUM(nett_profit) AS total_nett_profit,
  AVG(rating_transaksi) AS rata_rating_transaksi,
  MIN(date) AS tanggal_awal, MAX(date) AS tanggal_akhir
FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`;

-- Pendapatan tahunan dan pertumbuhan YoY. Tahun pertama tidak memiliki pembanding.
WITH annual AS (
  SELECT EXTRACT(YEAR FROM date) AS tahun,
    COUNT(DISTINCT transaction_id) AS total_transaksi,
    SUM(nett_sales) AS nett_sales, SUM(nett_profit) AS nett_profit
  FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final` GROUP BY tahun
)
SELECT *, SAFE_DIVIDE(nett_sales - LAG(nett_sales) OVER (ORDER BY tahun),
  LAG(nett_sales) OVER (ORDER BY tahun)) AS pertumbuhan_yoy
FROM annual ORDER BY tahun;

-- Top 10 provinsi berdasarkan transaksi
SELECT provinsi, COUNT(DISTINCT transaction_id) AS total_transaksi
FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`
GROUP BY provinsi ORDER BY total_transaksi DESC, provinsi LIMIT 10;

-- Top 10 provinsi berdasarkan nett sales
SELECT provinsi, SUM(nett_sales) AS nett_sales
FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`
GROUP BY provinsi ORDER BY nett_sales DESC, provinsi LIMIT 10;

-- Top 5: prioritaskan rating cabang tertinggi, lalu rata-rata rating transaksi terendah.
-- Interpretasi peringkat dijelaskan eksplisit karena panduan tidak menetapkan ambang.
SELECT branch_id, branch_name, kota, provinsi, MAX(rating_cabang) AS rating_cabang,
  AVG(rating_transaksi) AS rata_rating_transaksi,
  MAX(rating_cabang) - AVG(rating_transaksi) AS selisih_rating,
  COUNT(DISTINCT transaction_id) AS total_transaksi
FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`
GROUP BY branch_id, branch_name, kota, provinsi
ORDER BY rating_cabang DESC, rata_rating_transaksi ASC, branch_id LIMIT 5;

-- Peta profit provinsi
SELECT provinsi, SUM(nett_profit) AS nett_profit
FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`
GROUP BY provinsi ORDER BY nett_profit DESC;

-- Periksa keterhubungan inventory, tanpa menghilangkan transaksi yang tidak cocok.
SELECT tersedia_di_inventory, COUNT(*) AS total_transaksi, SUM(nett_sales) AS nett_sales
FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final` GROUP BY tersedia_di_inventory;
