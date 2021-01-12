--Tabla para guardar el xml
	DROP TABLE IF EXISTS XMLwithOpenXML3
	CREATE TABLE XMLwithOpenXML3(Id INT IDENTITY PRIMARY KEY, XMLData XML)

	--Se abre el archivo y se inserta el contenido en la tabla
    INSERT INTO XMLwithOpenXML3(XMLData)
    SELECT CONVERT(XML, BulkColumn) AS BulkColumn
    FROM OPENROWSET(BULK 'C:\Users\Allison\Documents\Semestre IV\Bases I\Datos-Tarea3.xml', SINGLE_BLOB) AS x;

	--Para mostrar el xml cargado correctamente
    SELECT * FROM XMLwithOpenXML3