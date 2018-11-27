-- Table that will hold the documents in the app.
drop view v_biblioteca
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
    documento           blob    NOT NULL
);

CREATE TABLE STATES(
    state_name          varchar(100)       PRIMARY KEY
)
select * from biblioteca;
INSERT INTO STATES VALUES ('Disponible');
INSERT INTO STATES VALUES ('Archivado');
INSERT INTO STATES VALUES ('Inactivo');
-- View for the interactive report that creates the documents.
CREATE VIEW v_biblioteca AS
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

-- Tables to hold document cluster clasifications.
create table PESO (       
       DOC_ID NUMBER,
       TEMA_ID NUMBER,
       PESO_SIMILITUD NUMBER);
create table TEMA (
       ID NUMBER,
       DESCRIPCION varchar2(4000),
       NOMBRE varchar2(200),
       TAMANO   number,
       PESO_CALIDAD number,
       parent number);

-- Stored procedure to generate the index
DROP INDEX "TEXTDEV"."DOCUMENTO_IDX";
CREATE INDEX "TEXTDEV"."DOCUMENTO_IDX" ON "TEXTDEV"."BIBLIOTECA" ("DOCUMENTO") 
   INDEXTYPE IS "CTXSYS"."CONTEXT"  PARAMETERS ('lexer MYLEXER stoplist CTXSYS.EMPTY_STOPLIST DATASTORE CTXSYS.DEFAULT_DATASTORE');
   
-- Calculate clusters
-- Place these in a stored procedure in the future
exec ctx_ddl.drop_preference('TEMAS_DOCUMENTOS');
exec ctx_ddl.create_preference('TEMAS_DOCUMENTOS','KMEAN_CLUSTERING');
exec ctx_ddl.set_attribute('TEMAS_DOCUMENTOS','CLUSTER_NUM','3');
   
exec ctx_output.start_log('my_log');
exec ctx_cls.clustering('"TEXTDEV"."DOCUMENTO_IDX"','id','PESO','TEMA','TEMAS_DOCUMENTOS');
exec ctx_output.end_log;
   
   
   

