-- View for the interactive report that creates the documents.
CREATE VIEW v_biblioteca AS
  SELECT 
    id, 
    titulo,
    fecha_creacion, 
    autores, 
    notas,
    tipo_documento AS Tipo_documento,
    tipo_archivo AS File_type,
    mimetype_archivo AS Tipo_archivo, 
    estado,
    usuario, 
    tags,
    nombre_archivo AS Nombre_del_archivo, 
    charset_archivo AS Set_de_caracteres, 
    fecha_carga AS Fecha_de_carga, 
    ult_act AS Última_actualización,
    sys.dbms_lob.getlength(documento) AS Tamaño,
    1 AS Descargar
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

CREATE INDEX "TEXTDEV"."DOCUMENTO_IDX" ON "TEXTDEV"."BIBLIOTECA" ("DOCUMENTO") 
   INDEXTYPE IS "CTXSYS"."CONTEXT"  PARAMETERS ('lexer MYLEXER stoplist CTXSYS.EMPTY_STOPLIST DATASTORE CTXSYS.DEFAULT_DATASTORE');
   
CREATE TABLE Biblioteca(
    titulo              varchar(500)     PRIMARY KEY,
    fecha_creacion      date,
    notas               varchar(1000),
    tipo_documento      varchar(18)     CHECK( tipo_documento IN ('Articulo', 'Brochure', 'Obra Literaria', 'Ensayo', 
                                        'Presentacion', 'Manual', 'Documento Tecnico', 'Otro') ) NOT NULL,
                                        
    tipo_archivo        varchar(10)     CHECK( tipo_archivo IN ('PDF', 'Word', 'Excel', 'PowerPoint', 'Texto', 'HTML', 
                                        'Keynote', 'Pages', 'Numbers', 'Otro') ),
                                        
    disponible          varchar(2)     CHECK( disponible IN ('si', 'no')),
    autores             varchar(300),
    fecha_carga         date,
    tam                 varchar(10),
    usuario             varchar(30),
    documento           blob    NOT NULL
);
