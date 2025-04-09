--check the dateset
SELECT *
	FROM PortfolioProject..NashvilleHousing
	

-- Standardize Data Format
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Datetime;

Update PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(datetime,SaleDate)

SELECT SaleDateConverted
	From PortfolioProject..NashvilleHousing

-- Populate Property Address Data
   -- Check duplicates in ParcellD, PropertyAddress, LegalReference
SELECT ParcelID, PropertyAddress, LegalReference, COUNT(*)
	From PortfolioProject..NashvilleHousing
	GROUP BY ParcelID,PropertyAddress, LegalReference
	HAVING COUNT(*) > 1

   -- Self Join
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
	FROM PortfolioProject..NashvilleHousing a
	JOIN PortfolioProject..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.UniqueID <> b.UniqueID
		WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
	FROM PortfolioProject..NashvilleHousing a
	JOIN PortfolioProject..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.UniqueID <> b.UniqueID	
		WHERE a.PropertyAddress IS NULL

-- Breaking out Address into Individual Columns (Address, City, State)
SELECT PropertyAddress, OwnerAddress
	From PortfolioProject..NashvilleHousing
	
SELECT SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress) - 1) AS Address, -- -1 is to get rid of ','
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
	From PortfolioProject..NashvilleHousing
	
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

Update PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress) - 1)	

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

Update PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))	

-- Breaking out OwnerAddress into Individual Columns (Address, City, State)
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
	FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

Update PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)	

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

Update PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

Update PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)	

-- Change 1 and 0 to Yes and No in "Sold as Vacant" field
-- Check the frequencies of Yes and No
SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
	FROM PortfolioProject..NashvilleHousing
	GROUP BY SoldAsVacant
	ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 0 THEN 'No'
	 WHEN SoldAsVacant = 1 THEN 'Yes'
END 
	 FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD SoldAsVacantYN NVARCHAR(3);

Update PortfolioProject..NashvilleHousing
SET SoldAsVacantYN = 
CASE WHEN SoldAsVacant = 0 THEN 'No'
	 WHEN SoldAsVacant = 1 THEN 'Yes'
END 

-- Remove Deplicates 
-- Create CTE
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--Delete Unused Columns
SELECT *
	FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress


--ETL
sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

USE PortfolioProject 
GO 

EXEC master.dbo.sp_MSset_oledb_prop 
	N'Microsoft.ACE.OLEDB.12.0', --The provider name
	N'AllowInProcess',           -- A security/property setting	  
	1                            -- Enable (1)
GO 

EXEC master.dbo.sp_MSset_oledb_prop 
	N'Microsoft.ACE.OLEDB.12.0', 
	N'DynamicParameters', 1 
GO 

SELECT NAME FROM SYS.TABLES;

--Using BULK INSERT
USE PortfolioProject;
GO
BULK INSERT nashvilleHousing FROM 'C:\Users\Zhongxiao Li\Documents\Practice dataset\Nashville Housing Data for Data Cleaning (reuploaded).csv'
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);
GO

---- Using OPENROWSET
USE PortfolioProject;
GO
SELECT * INTO nashvilleHousing
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 8.0; HDR=YES; 
	Database=C:\Users\Zhongxiao Li\Documents\Practice dataset\Nashville Housing Data for Data Cleaning (reuploaded).xls','SELECT * FROM [Sheet1$]');
GO