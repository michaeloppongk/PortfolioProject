/*
    Comprehensive Cleaning of Nashville Housing Data in SQL
    -------------------------------------------------------
    This script performs the following tasks:
    1. Standardizes the date format in the data.
    2. Populates missing property address data.
    3. Breaks down the address into individual columns (Address, City, State).
    4. Converts "Y/N" values to "Yes/No" in the "Sold as Vacant" field.
    5. Removes duplicate entries from the dataset.
    6. Handles missing and null values in key columns.
    7. Identifies and handles outliers in SalePrice.
    8. Adds indexes to optimize query performance.
    9. Deletes unused columns.
*/

--------------------------------------------------------------------------------------------------------------------------

-- 1. Standardize Date Format

-- Convert SaleDate to a standard date format and update the table

SELECT saleDateConverted, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing;

-- Update the SaleDate column with the converted date values
UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);

-- If the update doesn't work, add a new column and populate it with the converted dates
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

--------------------------------------------------------------------------------------------------------------------------

-- 2. Populate Missing Property Address Data

-- Retrieve records where PropertyAddress is missing
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

-- Use a self-join to fill missing property addresses based on matching ParcelID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Update the table with the populated property addresses
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

--------------------------------------------------------------------------------------------------------------------------

-- 3. Breaking Out Address into Individual Columns (Address, City, State)

-- Extract Address and City from PropertyAddress and update the table

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID;

-- Split PropertyAddress into Address and City components
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing;

-- Add new columns for split address components
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

-- Update the split address column with the extracted Address part
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

-- Update the split city column with the extracted City part
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Split OwnerAddress into separate components (Address, City, State)
SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing;

SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM PortfolioProject.dbo.NashvilleHousing;

-- Add and update split owner address columns
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255), OwnerSplitCity NVARCHAR(255), OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

--------------------------------------------------------------------------------------------------------------------------

-- 4. Convert "Y/N" to "Yes/No" in "Sold as Vacant" Field

-- Check distinct values in SoldAsVacant
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Update "SoldAsVacant" field to "Yes/No" instead of "Y/N"
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

--------------------------------------------------------------------------------------------------------------------------

-- 5. Remove Duplicate Entries

-- Use CTE to identify duplicate rows based on ParcelID, PropertyAddress, SalePrice, SaleDate, and LegalReference
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
-- Select rows identified as duplicates
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Delete duplicate rows from the table
DELETE FROM NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM RowNumCTE
    WHERE row_num > 1
);

--------------------------------------------------------------------------------------------------------------------------

-- 6. Handling Missing and Null Values

-- Check for any null values in important columns like SalePrice, SaleDate, etc.
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE SalePrice IS NULL OR SaleDate IS NULL OR PropertyAddress IS NULL;

-- Example: Set missing SalePrice to the median value
DECLARE @MedianSalePrice DECIMAL(18,2);

-- Calculate the median SalePrice
WITH MedianCTE AS (
    SELECT SalePrice,
           ROW_NUMBER() OVER (ORDER BY SalePrice) AS RowAsc,
           ROW_NUMBER() OVER (ORDER BY SalePrice DESC) AS RowDesc
    FROM PortfolioProject.dbo.NashvilleHousing
    WHERE SalePrice IS NOT NULL
)
SELECT @MedianSalePrice = AVG(SalePrice)
FROM MedianCTE
WHERE RowAsc = RowDesc OR RowAsc + 1 = RowDesc;

-- Update missing SalePrice with the calculated median
UPDATE PortfolioProject.dbo.NashvilleHousing
SET SalePrice = @MedianSalePrice
WHERE SalePrice IS NULL;

--------------------------------------------------------------------------------------------------------------------------

-- 7. Identify and Handle Outliers in SalePrice

-- Calculate interquartile range (IQR) for SalePrice to identify outliers
WITH IQRCTE AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY SalePrice) AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY SalePrice) AS Q3
    FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *,
    (Q3 - Q1) * 1.5 AS IQR
FROM IQRCTE;

-- Flag potential outliers (below Q1 - 1.5*IQR or above Q3 + 1.5*IQR)
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE SalePrice < (Q1 - IQR) OR SalePrice > (Q3 + IQR);

--------------------------------------------------------------------------------------------------------------------------

-- 8. Add Indexes for Better Performance

-- Add indexes on columns frequently used in WHERE, JOIN, and ORDER BY clauses
CREATE INDEX IDX_ParcelID ON PortfolioProject.dbo.NashvilleHousing (ParcelID);
CREATE INDEX IDX_SaleDate ON PortfolioProject.dbo.NashvilleHousing (SaleDate);
CREATE INDEX IDX_SalePrice ON PortfolioProject.dbo.NashvilleHousing (SalePrice);

--------------------------------------------------------------------------------------------------------------------------

-- 9. Delete Unused Columns

-- Drop columns that are no longer needed after cleaning
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

