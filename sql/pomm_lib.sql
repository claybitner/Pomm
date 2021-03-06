-- Pomm SQL library
-- This is free software, see the LICENCE file in the license directory
-- Copyright 2011 Grégoire HUBERT

-- is_email
-- Check if the given string is a valid email format or not
-- @param VARCHAR email the string to check
-- @return BOOLEAN 
CREATE OR REPLACE FUNCTION is_email(email VARCHAR) RETURNS BOOLEAN AS $$
BEGIN
      RETURN email ~* e'^([^@\\s]+)@((?:[a-z0-9-]+\\.)+[a-z]{2,})$';
END;
$$ LANGUAGE plpgsql;

-- email type
-- Varchar that verifies the is_email constraint
CREATE DOMAIN email AS VARCHAR CONSTRAINT valid_email CHECK(is_email(VALUE));

-- is_url
-- Check if the given string is a valid URL format
-- @param VARCHAR url 
-- @return BOOLEAN
CREATE OR REPLACE FUNCTION is_url(url VARCHAR) RETURNS BOOLEAN AS $$
BEGIN
      RETURN url ~* e'(https?|ftps?)://((([a-z0-9-]+\\.)+[a-z]{2,6})|(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}))(:[0-9]+)?(/\\S*)*$';
END;
$$ LANGUAGE plpgsql;

-- url type
-- Varchar that verifies the is_url constraint
CREATE DOMAIN url AS VARCHAR CONSTRAINT valid_url CHECK(is_url(VALUE));

-- transliterate
-- transform all non US chars to ASCII
-- @param VARCHAR my_text the text to transliterate
-- @return VARCHAR
CREATE OR REPLACE FUNCTION transliterate(my_text VARCHAR) RETURNS varchar AS $$
    DECLARE 
      text_out VARCHAR DEFAULT '';
    BEGIN
           text_out := my_text;
           text_out := translate(text_out, 'àâäåáăąãāçċćčĉéèėëêēĕîïìíīñôöøõōùúüûūýÿỳ', 'aaaaaaaaaccccceeeeeeeiiiiinooooouuuuuyyy');
           text_out := translate(text_out, 'ÀÂÄÅÁĂĄÃĀÇĊĆČĈÉÈĖËÊĒĔÎÏÌÍĪÑÔÖØÕŌÙÚÜÛŪÝŸỲ', 'AAAAAAAAACCCCCEEEEEEEIIIIINOOOOOUUUUUYYY');
           text_out := replace(text_out, 'æ', 'ae');
           text_out := replace(text_out, 'Œ', 'OE');
           text_out := replace(text_out, 'Æ', 'AE');
           text_out := replace(text_out, 'ß', 'ss');
           text_out := replace(text_out, 'œ', 'oe');

           RETURN text_out;
    END;
$$ LANGUAGE plpgsql;

-- slugify
-- transform a string so it keeps beeing readable in an URL
-- @param VARCHAR string
-- @return VARCHAR string
CREATE OR REPLACE FUNCTION slugify(string VARCHAR) RETURNS varchar AS $$
    BEGIN
          RETURN trim(both '-' from regexp_replace(lower(transliterate(string::varchar)), '[^a-z0-9]+', '-', 'g'));
    END;
$$ LANGUAGE plpgsql;

-- cut_nicely
-- cut strings on non word
-- @param VARCHAR string 
-- @param INTEGER my_length the minimum length before cutting
-- @return VARCHAR
CREATE OR REPLACE FUNCTION cut_nicely(my_string VARCHAR, my_length INTEGER) RETURNS varchar AS $$
    DECLARE
        my_pointer INTEGER;
    BEGIN
        my_pointer := my_length;
        WHILE my_pointer < length(my_string) AND substr(my_string, my_pointer, 1) ~* '[À-ÿa-z0-9-]' LOOP
            my_pointer := my_pointer + 1;
        END LOOP;

        RETURN substr(my_string, 1, my_pointer - 1);
    END;
$$ LANGUAGE plpgsql
;

-- update updated_at
-- to be called by a TRIGGER to update the updated_at field of a table
-- the field updated_at has to be any type that accepts now().
-- @return TRIGGER
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
  BEGIN
    NEW.updated_at := now();

    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;
