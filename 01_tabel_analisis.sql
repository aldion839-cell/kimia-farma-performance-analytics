-- GoogleSQL / BigQuery. Project: intership-project-kimia-farma.
-- Prasyarat: empat CSV sudah diimpor ke dataset kimia_farma.
-- Saat impor, gunakan date STRING dan price/discount_percentage/rating NUMERIC.
-- Script tidak menimpa tabel analisis yang sudah ada.

ASSERT (SELECT COUNT(*) = COUNT(DISTINCT transaction_id)
  FROM `intership-project-kimia-farma.kimia_farma.kf_final_transaction`)
  AS 'transaction_id harus unik dan tidak NULL';
ASSERT (SELECT COUNT(*) = COUNT(DISTINCT branch_id)
  FROM `intership-project-kimia-farma.kimia_farma.kf_kantor_cabang`)
  AS 'branch_id master harus unik dan tidak NULL';
ASSERT (SELECT COUNT(*) = COUNT(DISTINCT product_id)
  FROM `intership-project-kimia-farma.kimia_farma.kf_product`)
  AS 'product_id master harus unik dan tidak NULL';
ASSERT (SELECT COUNTIF(SAFE.PARSE_DATE('%m/%d/%Y', date) IS NULL
  OR SAFE.PARSE_DATE('%m/%d/%Y', date) NOT BETWEEN DATE '2020-01-01' AND DATE '2023-12-31'
  OR price IS NULL OR price < 0
  OR discount_percentage IS NULL OR discount_percentage NOT BETWEEN 0 AND 1
  OR rating IS NULL OR rating NOT BETWEEN 1 AND 5) = 0
  FROM `intership-project-kimia-farma.kimia_farma.kf_final_transaction`)
  AS 'Periksa tanggal, harga, diskon, dan rating transaksi';
ASSERT (SELECT COUNT(*) = 0
  FROM `intership-project-kimia-farma.kimia_farma.kf_final_transaction` t
  LEFT JOIN `intership-project-kimia-farma.kimia_farma.kf_kantor_cabang` b USING (branch_id)
  LEFT JOIN `intership-project-kimia-farma.kimia_farma.kf_product` p USING (product_id)
  WHERE b.branch_id IS NULL OR p.product_id IS NULL)
  AS 'Terdapat transaksi tanpa master cabang atau produk';

CREATE TABLE `intership-project-kimia-farma.kimia_farma.kf_analisis_final`
CLUSTER BY provinsi, branch_id
AS
WITH inventory_keys AS (
  -- Hanya ringkas keberadaan inventory. Stok tanpa tanggal tidak dianggap
  -- sebagai stok historis atau dijumlahkan berulang pada setiap transaksi.
  SELECT branch_id, product_id, COUNT(*) AS jumlah_record_inventory
  FROM `intership-project-kimia-farma.kimia_farma.kf_inventory`
  GROUP BY branch_id, product_id
), base AS (
  SELECT
    t.transaction_id,
    PARSE_DATE('%m/%d/%Y', t.date) AS date,
    t.branch_id,
    b.branch_name,
    b.kota,
    b.provinsi,
    b.rating AS rating_cabang,
    t.customer_name,
    t.product_id,
    p.product_name,
    CAST(t.price AS NUMERIC) AS actual_price,
    CAST(t.discount_percentage AS NUMERIC) AS discount_percentage,
    CASE
      WHEN t.price <= 50000 THEN NUMERIC '0.10'
      WHEN t.price <= 100000 THEN NUMERIC '0.15'
      WHEN t.price <= 300000 THEN NUMERIC '0.20'
      WHEN t.price <= 500000 THEN NUMERIC '0.25'
      ELSE NUMERIC '0.30'
    END AS persentase_gross_laba,
    t.rating AS rating_transaksi,
    b.branch_category,
    p.product_category,
    i.jumlah_record_inventory IS NOT NULL AS tersedia_di_inventory
  FROM `intership-project-kimia-farma.kimia_farma.kf_final_transaction` t
  LEFT JOIN `intership-project-kimia-farma.kimia_farma.kf_kantor_cabang` b USING (branch_id)
  LEFT JOIN `intership-project-kimia-farma.kimia_farma.kf_product` p USING (product_id)
  LEFT JOIN inventory_keys i USING (branch_id, product_id)
), sales AS (
  SELECT *, actual_price * (1 - discount_percentage) AS nett_sales FROM base
)
SELECT transaction_id, date, branch_id, branch_name, kota, provinsi,
  rating_cabang, customer_name, product_id, product_name, actual_price,
  discount_percentage, persentase_gross_laba, nett_sales,
  nett_sales * persentase_gross_laba AS nett_profit,
  rating_transaksi, branch_category, product_category, tersedia_di_inventory
FROM sales;

-- nett_profit adalah estimasi sesuai asumsi tugas: nett_sales x tarif laba.
-- Dataset tidak memuat HPP/biaya operasi/pajak, sehingga bukan laba bersih akuntansi.
ASSERT (SELECT COUNT(*) FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`) =
  (SELECT COUNT(*) FROM `intership-project-kimia-farma.kimia_farma.kf_final_transaction`)
  AS 'Jumlah baris berubah setelah join';
ASSERT (SELECT SUM(nett_sales) FROM `intership-project-kimia-farma.kimia_farma.kf_analisis_final`) =
  (SELECT SUM(CAST(price AS NUMERIC) * (1 - CAST(discount_percentage AS NUMERIC)))
   FROM `intership-project-kimia-farma.kimia_farma.kf_final_transaction`)
  AS 'Total penjualan tidak cocok dengan sumber';
