CREATE TRIGGER bitacoraCO_Update1
ON dbo.CuentaObjetivo
AFTER Update
AS 
BEGIN
  DECLARE @Usuario nchar(30)
  DECLARE @IP nchar(30)
  DECLARE @Fecha date
  Declare @XMLAntes xml
  DECLARE @XMLDespues xml

  SELECT @Usuario = INSERTED.InsertedBy FROM INSERTED
  SELECT @Fecha = INSERTED.InsertedAt FROM INSERTED
  SELECT @IP = '190.113.111.23'
  
  --Se forma el xml antes
  SET @XMLAntes = (SELECT * FROM DELETED FOR XML PATH('CuentaOriginal'), ROOT('CuentasObjetivo'))
  --Se forma el xml después
  SET @XMLDespues = (SELECT * FROM INSERTED FOR XML PATH('CuentaModificada'), ROOT('CuentasObjetivo'))   

  INSERT INTO dbo.Evento(TipoEventoID, UsuarioID, IPnumber, Fecha, XMLAntes, XMLDespues) 
  VALUES (5, @Usuario, @IP, @Fecha, @XMLAntes, @XMLDespues)
END;


