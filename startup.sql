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

