USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PAG_Top_10_Empresas]    Script Date: 15/06/2022 11:22:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Gonzalo Racero Galán
-- Create date: 27/04/2022
-- Descrption:	Obtener Top 10 Empresas con mas seguidores
-- ============================================

ALTER PROCEDURE [dbo].[PAG_Top_10_Empresas]
		-- es un get, no necesito esto @JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT
	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Encontradas empresas con mas seguidores'
		-- me creo una tabla en la que guardo el top de IDS
		DECLARE @TOP_EMPRESAS_CON_MAS_SEGUIDRES TABLE (
			id INT
		)

	BEGIN TRY

		SET NOCOUNT ON;
		
		-- le pregunto a la tabla de seguidor seguido cuantas veces una empresa como seguido
		INSERT INTO @TOP_EMPRESAS_CON_MAS_SEGUIDRES 
		SELECT TOP 10 Empresa.Id
			FROM Seguidor_Seguido RIGHT JOIN Empresa
			ON (Empresa.Id = Seguidor_Seguido.Seguido)
			WHERE Empresa.Eliminado = 0
			GROUP BY (Empresa.Id)
			order by count(Seguidor) desc
		

		-- me guardo esas empresas en el json de retorno
		SET @JSON_OUT = ( 
					SELECT  DISTINCT
						USUARIO.Id,
						USUARIO.Correo,
						USUARIO.Contrasena,
						USUARIO.Nick,
						USUARIO.Foto_Perfil,
						USUARIO.Foto_Fondo,
						USUARIO.Telefono,
						USUARIO.Frase,
						EMPRESA.Nombre_Empresa,
						EMPRESA.Cif,
						EMPRESA.Direccion_Facturacion,
						EMPRESA.Direccion_Fiscal,
						EMPRESA.Nombre_Persona,
						EMPRESA.Apellido1_Persona,
						EMPRESA.Apellido2_Persona,
						EMPRESA.Dni_Persona,
					(SELECT COUNT(s.Seguidor) FROM Seguidor_Seguido s  WHERE s.Seguido = Usuario.id) AS 'Seguidores'
					FROM USUARIO INNER JOIN EMPRESA
					ON (Usuario.Id = Empresa.Id)
					WHERE USUARIO.Eliminado = 0  AND Empresa.Eliminado = 0 -- miro que no haya sido borrado
						AND Usuario.Id = ANY (SELECT Id FROM @TOP_EMPRESAS_CON_MAS_SEGUIDRES)
					ORDER BY Seguidores DESC
				FOR JSON PATH) 

			IF (@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'No hay empresas.'
			END

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
	END CATCH
