USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PAG_Top_10_Personas]    Script Date: 15/06/2022 11:22:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Gonzalo Racero Galán
-- Create date: 27/04/2022
-- Descrption:	Obtener Top 10 Personas con mas seguidores
-- ============================================

ALTER PROCEDURE [dbo].[PAG_Top_10_Personas]
		-- es un get, no necesito esto @JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT
	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Encontradas personas con mas seguidores.'
		-- me creo una tabla en la que guardo el top de IDS
		DECLARE @TOP_PERSONAS_CON_MAS_SEGUIDRES TABLE (
			id INT
		)

	BEGIN TRY

		SET NOCOUNT ON;
		
		-- le pregunto a la tabla de seguidor seguido cuantas veces una empresa como seguido
		INSERT INTO @TOP_PERSONAS_CON_MAS_SEGUIDRES 
		SELECT TOP 10 Persona.Id
			FROM Seguidor_Seguido RIGHT JOIN Persona
			ON (Persona.Id = Seguidor_Seguido.Seguido)
			WHERE Persona.Eliminado = 0
			GROUP BY (Persona.Id)
			order by count(Seguidor) desc
		
		-- para comprobar que esa tabla funciona 
		--SET @JSON_OUT = (SELECT * FROM @TOP_EMPRESAS_CON_MAS_SEGUIDRES AS empresasPRO FOR JSON PATH)

		-- me guardo esas empresas en el json de retorno
		SET @JSON_OUT = ( 
					SELECT TOP 10  
						USUARIO.Id,
						USUARIO.Correo,
						USUARIO.Contrasena,
						USUARIO.Nick,
						USUARIO.Foto_Perfil,
						USUARIO.Foto_Fondo,
						USUARIO.Telefono,
						USUARIO.Frase,
						PERSONA.Dni,
						PERSONA.Nombre,
						PERSONA.Apellido1,
						PERSONA.Apellido2,
						PERSONA.Fecha_Nacimiento,
						SEXO.Id AS 'Sexo.Id',
						SEXO.Sexo AS 'Sexo.Sexo',
					(SELECT COUNT(s.Seguidor) FROM Seguidor_Seguido s  WHERE s.Seguido = Usuario.id) AS 'Seguidores'
					FROM USUARIO INNER JOIN PERSONA ON (Usuario.Id = PERSONA.Id)
						INNER JOIN SEXO ON (SEXO.Id = Persona.Sexo)
					WHERE USUARIO.Eliminado = 0  AND PERSONA.Eliminado = 0 AND SEXO.Eliminado = 0-- miro que no haya sido borrado
						AND Usuario.Id = ANY (SELECT Id FROM @TOP_PERSONAS_CON_MAS_SEGUIDRES)
					ORDER BY Seguidores DESC
				FOR JSON PATH) 

			IF (@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'No hay personas con seguidores.'
			END

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
	END CATCH
