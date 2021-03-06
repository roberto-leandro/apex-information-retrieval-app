-- Table that will hold the documents in the app.
DROP TABLE BIBLIOTECA;
CREATE TABLE BIBLIOTECA(
    id                  number           PRIMARY KEY, 
    titulo              varchar(500)     NOT NULL,
    fecha_creacion      date,
    notas               varchar(1000),
    tipo_documento      varchar(18)     CHECK( tipo_documento IN ('Articulo', 'Brochure', 'Obra Literaria', 'Ensayo', 
                                        'Presentacion', 'Manual', 'Documento Tecnico', 'Otro') ) NOT NULL,
                                        
    tipo_archivo        varchar(10)     CHECK( tipo_archivo IN ('PDF', 'Word', 'Excel', 'PowerPoint', 'Texto', 'HTML', 
                                        'Keynote', 'Pages', 'Numbers', 'Otro') ),
    mimetype_archivo    VARCHAR(256),
    estado              varchar(10)     CHECK( estado IN ('Archivado', 'Disponible', 'Inactivo') ),
    tags                varchar(1000),
    nombre_archivo      varchar(1000),
    charset_archivo     varchar(256),
    fecha_actualizacion date,
    autores             varchar(300),
    fecha_carga         date,
    usuario             varchar(30),
    documento           blob   
);

-- View for the interactive report that creates the documents.
DROP VIEW V_BIBLIOTECA;
CREATE VIEW V_BIBLIOTECA AS
  SELECT 
    id, 
    titulo,
    fecha_creacion, 
    autores, 
    notas,
    tipo_documento,
    tipo_archivo,
    mimetype_archivo, 
    estado,
    usuario, 
    tags,
    nombre_archivo, 
    charset_archivo, 
    fecha_carga, 
    fecha_actualizacion,
    CONCAT(ROUND(sys.dbms_lob.getlength(documento)/1024, 2),'MB') AS tamaño,
    1 AS descargar
    FROM Biblioteca;
    
--View search
DROP VIEW V_FILTRO_BIBLIOTECA;
CREATE VIEW V_FILTRO_BIBLIOTECA AS
    SELECT 
        id,
        titulo,
        tipo_archivo,
        tipo_documento,
        autores,
        nombre_archivo,
        CONCAT(ROUND(sys.dbms_lob.getlength(documento)/1024, 2),'MB') AS tamaño,
        fecha_creacion,
        estado,
        1 AS descargar,
        2 AS markup,
        3 AS temas,
        documento
    FROM Biblioteca
    WHERE
        estado = 'Disponible'    
;

--Search query used in the APEX application
/*
SELECT
    SCORE(1), 
    id, 
	titulo, 
    tipo_archivo, 
    tipo_documento, 
    autores, 
    nombre_archivo, 
    tamaño, 
    fecha_creacion,
	estado,
    descargar, 
    markup, 
    temas
FROM v_filtro_biblioteca v
WHERE 
    ( :P6_CLASE = 'Todos' OR :P6_CLASE = tipo_documento ) 
    AND ( :P6_TIPO_ARCHIVO = 'Todos' OR :P6_TIPO_ARCHIVO = tipo_archivo )
    AND ( :P6_EXPRESION IS NOT NULL AND ( CONTAINS(v.documento, CONCAT(CONCAT('about(',:P6_EXPRESION),')'), 1) > :P6_SCORE ) )
*/

-- Contains all the themes in the collection.
DROP TABLE THEME;
CREATE TABLE THEME(
    query_id            number, 
    theme               varchar2(2000)     NOT NULL,
    weight              number
);

-- Contains gists for each document.
DROP TABLE GIST;
CREATE TABLE GIST (
    query_id            number,
    pov                 varchar2(80),
    gist                clob 
);


-- Stored procedure to generate the index
DROP INDEX docs_index;
exec ctx_ddl.create_preference('english_lexer','basic_lexer');
exec ctx_ddl.set_attribute('english_lexer','index_themes','yes');
exec ctx_ddl.set_attribute('english_lexer','theme_language','english');
CREATE INDEX docs_index ON "TEXTDEV"."BIBLIOTECA" ("DOCUMENTO") 
   INDEXTYPE IS "CTXSYS"."CONTEXT"  PARAMETERS ('lexer english_lexer');

-- Stored procedures to re-clasify documents, generating themes and gists for each document.
-- Themes
EXEC ctx_doc.themes(            -
    index_name => 'docs_index', -
    restab => 'THEME',          -
    textkey => 121,             -
    full_themes => FALSE        
);

-- Gists
EXEC ctx_doc.gist (             -
    index_name => 'docs_index', -
    textkey => '121',           -
    restab => 'gists_table'     
);


CREATE PROCEDURE UPDATE_THEMES( ID Number ) AS
BEGIN
    
    DELETE FROM THEME
    WHERE query_id = ID;
    
    ctx_doc.themes( index_name => 'docs_index', restab => 'THEME', textkey => ID, query_id => ID, full_themes => FALSE );
    
END;

CREATE PROCEDURE UPDATE_GIST( ID Number, THEME varchar ) AS
BEGIN
    
    DELETE FROM GIST
    WHERE query_id = ID;
    
    ctx_doc.gist ( index_name => 'docs_index', textkey => ID, query_id => ID, restab => 'gists_table', pov => THEME );
    
END;

set define off;
CREATE OR REPLACE PROCEDURE GENERATE_MARKUP (ID NUMBER, QUERY VARCHAR) IS
--DECLARE
    HTML_CLOB               CLOB;
    CONVERTED_BLOB          BLOB;
    offset1                 integer;
    offset2                 integer;
    context                 integer;
    warning                 integer;
    v_id                    integer;
BEGIN
    -- Generate the markup
    ctx_doc.markup (index_name  => 'docs_index',
    textkey                     => TO_CHAR(ID ),
    text_query                  => QUERY,
    restab                      => HTML_CLOB,
    starttag                    => '<A NAME=ctx%CURNUM><i><font color=red><B>',
    endtag                      => '</B></font></i></A>',
    prevtag                     => '<A HREF=#ctx%PREVNUM>&lt;</A>',
    nexttag                     => '<A HREF=#ctx%NEXTNUM>&gt;</A>');

    -- Initialize variables to convert the clob to blob
    offset1 := 1;
    offset2 := 1;
    context := 0;
    warning := 0;
    DBMS_LOB.CreateTemporary(CONVERTED_BLOB, true);
  
    -- Convert the resulting clob into a blob to be downloaded
    DBMS_LOB.ConvertToBlob(CONVERTED_BLOB, HTML_CLOB, length(HTML_CLOB), offset1, offset2, 0, context, warning);

    -- Download the blob
    wwv_flow_file_mgr.download_file( p_file_content => CONVERTED_BLOB,
    p_file_name => 'file'||to_char(v_id,'fm00009')||'.html',
    p_mime_type => 'text/html',
    p_file_charset => 'UTF-8',
    p_last_updated_on => sysdate,
    p_etag => '');
END;


---------------------

DECLARE
 	CURSOR biblioteca_id_cur
 	IS
     	SELECT id
    	FROM BIBLIOTECA;

 	l_biblioteca_id   biblioteca_id_cur%ROWTYPE;
  BEGIN
 	OPEN biblioteca_id_cur;

	LOOP
    	FETCH biblioteca_id_cur INTO l_biblioteca_id;
    	EXIT WHEN biblioteca_id_cur%NOTFOUND;
    	UPDATE_THEMES(l_biblioteca_id);
	END LOOP;

 	CLOSE biblioteca_id_cur;
 END;



CREATE OR REPLACE PROCEDURE classify_documents IS
 	CURSOR biblioteca_id_cur
 	IS
     	SELECT id
    	FROM BIBLIOTECA;

 	l_biblioteca_id   number;
  BEGIN
 	OPEN biblioteca_id_cur;

	LOOP
    	FETCH biblioteca_id_cur INTO l_biblioteca_id;
    	UPDATE_THEMES(l_biblioteca_id);
        EXIT WHEN biblioteca_id_cur%NOTFOUND;
	END LOOP;

 	CLOSE biblioteca_id_cur;
 END;

