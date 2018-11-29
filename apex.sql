-- Table that will hold the documents in the app.
drop TABLE biblioteca
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
    CONCAT(ROUND(sys.dbms_lob.getlength(documento)/1024, 2),'MB') AS tamano,
    1 AS descargar
    FROM Biblioteca;

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

-- Stored procedure to re-clasify documents, generating themes and gists for each document.
-- Themes
DROP TABLE THEME;
EXEC ctx_doc.themes(            -
    index_name => 'docs_index', -
    restab => 'THEME',          -
    textkey => 121,             -
    full_themes => FALSE        -
);

-- Gists
DROP TABLE GIST;
EXEC ctx_doc.gist (             -
    index_name => 'docs_index', -
    textkey => '121',           -
    restab => 'gists_table'     -
);




