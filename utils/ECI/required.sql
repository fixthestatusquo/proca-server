SELECT
  ctr.code, cp.required, prop.`name` as prop, prop.`type`, prop.priority, pg.`name` as `group`, pg.multichoice, pg.priority

  FROM OCT_COUNTRY ctr 
         JOIN OCT_COUNTRY_PROPERTY cp ON ctr.id = cp.country_id
         JOIN OCT_PROPERTY prop ON prop.id = cp.property_id
         JOIN OCT_PROPERTY_GROUP pg ON pg.id = prop.group_id
 ORDER BY 1, prop.priority
          ;

-- GENERATE REQUIRED
SELECT 
  concat('"', code, '" => [', fields, '],') as aa
  FROM (
    SELECT
      code,
      GROUP_CONCAT( field SEPARATOR ', ') as fields

      FROM (
        SELECT
          ctr.code, concat('"', replace(prop.`name`, 'oct.property.', ''), '"') as field
          FROM OCT_COUNTRY ctr 
                 JOIN OCT_COUNTRY_PROPERTY cp ON ctr.id = cp.country_id
                 JOIN OCT_PROPERTY prop ON prop.id = cp.property_id
                 JOIN OCT_PROPERTY_GROUP pg ON pg.id = prop.group_id
      ) x
             
     GROUP BY 1
  ) y
;
-- LIST multichoice fields
SELECT 
  distinct
    REPLACE(REPLACE(prop.`name`, 'oct.property.', ''), '.', '_')

  FROM OCT_COUNTRY ctr 
         JOIN OCT_COUNTRY_PROPERTY cp ON ctr.id = cp.country_id
         JOIN OCT_PROPERTY prop ON prop.id = cp.property_id
         JOIN OCT_PROPERTY_GROUP pg ON pg.id = prop.group_id
 WHERE pg.multichoice > 0;
