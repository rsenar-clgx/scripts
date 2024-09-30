BEGIN

DECLARE CasePartValue STRING DEFAULT '';
DECLARE CharName STRING DEFAULT '';
DECLARE DestCol STRING DEFAULT '';
DECLARE create_table STRING DEFAULT '';

DECLARE i INT64 DEFAULT 1;
DECLARE row_count INT64;
DECLARE sql STRING DEFAULT '';

SET sql = 'SELECT CLIP,address_id,struct_id';

IF var_source = 'tax' THEN
  SET sql = 'SELECT StagingParcel.CLIP,StagingBuilding.address_id,StagingBuilding.struct_id';
END IF;

CREATE OR REPLACE TEMP TABLE temp_dist_sdp_transformational_rules
AS
SELECT
  Characteristic, DestinationColumn,
  ROW_NUMBER() OVER() AS row_number
FROM edr_pmd_property_commercial_prefill.commercial_prefill_transformation_rules
WHERE UPPER(SOURCE) = UPPER(var_source)
GROUP BY
  Characteristic, DestinationColumn;

SET row_count = (SELECT COUNT(*) FROM temp_dist_sdp_transformational_rules);

WHILE i <= row_count
DO

SET CharName = (SELECT Characteristic FROM temp_dist_sdp_transformational_rules WHERE row_number = i);
SET DestCol = (SELECT DestinationColumn FROM temp_dist_sdp_transformational_rules WHERE row_number = i);
SET CasePartValue = '';
SET CasePartValue = (SELECT STRING_AGG (concat_string, " ")
FROM (
  SELECT
    CASE
      WHEN AssignmentType = 'Value' THEN CASE
      WHEN (Rule1 = 'Equal'
      OR Rule1 = '=')
    AND SourceValue1 = 'Any' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' IS NOT NULL ' ||
    CASE
      WHEN Rule2 = 'Equal' OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || 'THEN ' || DestinationValue || ' '
      WHEN Rule1 = 'Equal' OR Rule1 = '=' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' = \'' || SourceValue1 || '\'' || CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      WHEN Rule2 IS NULL THEN ''
      WHEN Rule2 = 'LessThan' THEN ' AND ' || SourceTable || '.' || SourceField2 || ' < ' || SourceValue2 || ''
      WHEN Rule2 = 'Greater' THEN ' AND ' || SourceTable || '.' || SourceField2 || ' > ' || SourceValue2 || ''
      WHEN Rule2 = 'Between' THEN ' AND ' || SourceTable || '.' || SourceField2 || ' BETWEEN ' || TRIM(SUBSTR(SourceValue2, 1, INSTR(SourceValue2, '-') - 1)) || ' AND ' || TRIM(SUBSTR(SourceValue2, INSTR(SourceValue2, '-') + 1, LENGTH(SourceValue2)))
      ELSE ''
  END
    || ' THEN ' || DestinationValue || ' '
      WHEN Rule1 = 'Anywhere in field' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' LIKE \'%' || SourceValue1 || '%\'' || CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' || DestinationValue || ' '
      WHEN Rule1 = 'Ends with' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' LIKE \'%' || SourceValue1 || '\'' || CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' || DestinationValue || ' '
      ELSE ''
  END
      WHEN AssignmentType = 'SourceField1' THEN CASE
      WHEN (Rule1 = 'Equal'
      OR Rule1 = '=')
    AND SourceValue1 = 'Any' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' IS NOT NULL' ||
    CASE
      WHEN Rule2 = 'Equal' OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' ||
  IF
    (SourceField1 LIKE '%Stories%', 'IF(CAST(' || SourceTable || '.' || SourceField1 || ' AS NUMERIC) < 0.5, 1, CAST(ROUND(' || SourceTable || '.' || SourceField1 || ', 0) AS INT64))', SourceTable || '.' || SourceField1) || ' '
      WHEN Rule1 = 'Equal' OR Rule1 = '=' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' = \'' || SourceValue1 || '\'' || CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' ||
  IF
    (SourceField1 LIKE '%Stories%', 'IF(CAST(' || SourceTable || '.' || SourceField1 || ' AS NUMERIC) < 0.5, 1, CAST(ROUND(' || SourceTable || '.' || SourceField1 || ', 0) AS INT64))', SourceTable || '.' || SourceField1) || ' '
      WHEN Rule1 = 'Anywhere in field' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' LIKE \'%' || SourceValue1 || '%\'' || CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' ||
  IF
    (SourceField1 LIKE '%Stories%', 'IF(CAST(' || SourceTable || '.' || SourceField1 || ' AS NUMERIC) < 0.5, 1, CAST(ROUND(' || SourceTable || '.' || SourceField1 || ', 0) AS INT64))', SourceTable || '.' || SourceField1) || ' '
      WHEN Rule1 = 'Ends with' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' LIKE \'%' || SourceValue1 || '\''|| CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' ||
  IF
    (SourceField1 LIKE '%Stories%', 'IF(CAST(' || SourceTable || '.' || SourceField1 || ' AS NUMERIC) < 0.5, 1, CAST(ROUND(' || SourceTable || '.' || SourceField1 || ', 0) AS INT64))', SourceTable || '.' || SourceField1) || ' '
      ELSE ''
  END
      WHEN AssignmentType = 'SourceField2' THEN CASE
      WHEN (Rule1 = 'Equal'
      OR Rule1 = '=')
    AND SourceValue1 = 'Any' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' IS NOT NULL' ||
    CASE
      WHEN Rule2 = 'Equal' OR Rule2 = '=' THEN ' AND '|| SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' ||
  IF
    (SourceField2 LIKE '%Stories%', 'IF(CAST(' || SourceTable || '.' || SourceField1 || ' AS NUMERIC) < 0.5, 1, CAST(ROUND(' || SourceTable || '.' || SourceField1 || ', 0) AS INT64))', SourceTable || '.' || SourceField2) || ' '
      WHEN Rule1 = 'Equal' OR Rule1 = '=' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || '=\'' || SourceValue1 || '\'' || CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND ' || SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND ' || SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' ||
  IF
    (SourceField2 LIKE '%Stories%', 'IF(CAST(' || SourceTable || '.' || SourceField1 || ' AS NUMERIC) < 0.5, 1, CAST(ROUND(' || SourceTable || '.' || SourceField1 || ', 0) AS INT64))', SourceTable || '.' || SourceField2) || ' '
      WHEN Rule1 = 'Anywhere in field' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' LIKE \'%' || SourceValue1 || '%\'' || CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND ' || SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND ' || SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' ||
  IF
    (SourceField2 LIKE '%Stories%', 'IF(CAST(' || SourceTable || '.' || SourceField1 || ' AS NUMERIC) < 0.5, 1, CAST(ROUND(' || SourceTable || '.' || SourceField1 || ', 0) AS INT64))', SourceTable || '.' || SourceField2) || ' '
      WHEN Rule1 = 'Ends with' THEN 'WHEN ' || SourceTable || '.' || SourceField1 || ' LIKE \'%' || SourceValue1 || '\'' || CASE
      WHEN Rule2 = 'Equal'
    OR Rule2 = '=' THEN ' AND ' || SourceTable || '.' || SourceField2 || '=\'' || SourceValue2 || '\''
      WHEN Rule2 = 'Anywhere in field' THEN ' AND ' || SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '%\''
      WHEN Rule2 = 'Ends with' THEN ' AND '|| SourceTable || '.' || SourceField2 || ' LIKE \'%' || SourceValue2 || '\''
      ELSE ''
  END
    || ' THEN ' ||
  IF
    (SourceField2 LIKE '%Stories%', 'IF(CAST(' || SourceTable || '.' || SourceField1 || ' AS NUMERIC) < 0.5, 1, CAST(ROUND(' || SourceTable || '.' || SourceField1 || ', 0) AS INT64))', SourceTable || '.' || SourceField2) || ' '
      ELSE ''
  END
      ELSE ''
  END
    AS concat_string
  FROM edr_pmd_property_commercial_prefill.commercial_prefill_transformation_rules
  WHERE Characteristic = CharName
      AND DestinationColumn = DestCol
      AND UPPER(SOURCE) = UPPER(var_source)
  ORDER BY Priority
));

IF CasePartValue <> '' THEN
    SET sql = sql || ', CASE ' || CasePartValue || ' ELSE NULL END ' || DestCol;
END IF;

SET i=i+1;

END WHILE;

IF var_source = 'tax' THEN
    SET sql = sql || ' FROM stg_property_commercial_prefill.stg_' || var_source || '_pcl_pre_transform AS StagingParcel LEFT JOIN stg_property_commercial_prefill.stg_'|| var_source || '_bldg_pre_transform AS StagingBuilding on StagingParcel.CLIP=StagingBuilding.CLIP';
ELSE
    SET sql = sql || ' FROM stg_property_commercial_prefill.stg_' || var_source || '_pre_transform AS StagingParcel';
END IF;

SET create_table = 'CREATE OR REPLACE table stg_property_commercial_prefill.stg_' || var_source || '_transform_core AS ' || sql;

EXECUTE IMMEDIATE create_table;
    END