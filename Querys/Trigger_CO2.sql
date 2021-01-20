CREATE TRIGGER bitacoraCO_Delete1
ON dbo.CuentaObjetivo
AFTER DELETE
AS 
BEGIN
  DECLARE @Usuario nchar(30)
  DECLARE @IP nchar(30)
  DECLARE @Fecha date
  Declare @XMLAntes xml
  DECLARE @XMLDespues xml

  SELECT @Usuario = DELETED.InsertedBy FROM DELETED
  SELECT @Fecha = DELETED.InsertedAt FROM DELETED
  SELECT @IP = '190.113.111.23'
  
  --Se forma el xml después
  SET @XMLAntes = (SELECT * FROM INSERTED FOR XML PATH('CuentaEliminada'), ROOT('CuentasObjetivo'))

  INSERT INTO dbo.Evento(TipoEventoID, UsuarioID, IPnumber, Fecha, XMLAntes, XMLDespues) 
  VALUES (6, @Usuario, @IP, @Fecha, @XMLAntes, @XMLDespues)
END;