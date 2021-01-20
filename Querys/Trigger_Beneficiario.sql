CREATE TRIGGER bitacoraBeneficiario_Insert1
ON dbo.Beneficiario
AFTER INSERT
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
  
  --Se forma el xml después
  SET @XMLDespues = (SELECT * FROM INSERTED FOR XML PATH('NuevoBeneficiario'), ROOT('Beneficiarios') )

  INSERT INTO dbo.Evento(TipoEventoID, UsuarioID, IPnumber, Fecha, XMLAntes, XMLDespues) 
  VALUES (1, @Usuario, @IP, @Fecha, @XMLAntes, @XMLDespues)
END;