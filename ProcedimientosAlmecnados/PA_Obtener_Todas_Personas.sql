USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Todas_Personas]    Script Date: 05/06/2022 18:12:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de todos los usuarios Persona
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Todas_Personas]
	
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Usuarios devueltos exitosamente'

		DECLARE @TOP_USUARIOS TABLE (Id INT)
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SET NOCOUNT ON;

		INSERT INTO @TOP_USUARIOS 
		SELECT TOP 100 Usuario.Id
			FROM Seguidor_Seguido RIGHT JOIN Usuario
			ON (Usuario.Id = Seguidor_Seguido.Seguido)
			WHERE Usuario.Eliminado = 0
			GROUP BY (Usuario.Id)
			order by count(Seguidor) desc

		-- Crear JSON de respuesta a raiz de la consulta

		SET @JSON_OUT = (
			
			SELECT u.Id,
					u.Correo,
					u.Contrasena,
					u.Nick,
					u.Foto_Fondo,
					u.Foto_Perfil,
					u.Telefono,
					u.Frase,
					p.Dni,
					p.Nombre,
					p.Apellido1,
					p.Apellido2,
					s.Id AS 'Sexo.Id',
					s.Sexo AS 'Sexo.Sexo',
					p.Fecha_Nacimiento,
					(SELECT COUNT(s.Seguidor) FROM Seguidor_Seguido s  WHERE s.Seguido = u.id) AS 'Seguidores'
			FROM Usuario u INNER JOIN Persona p ON (u.Id = p.Id) INNER JOIN Sexo s ON (p.Sexo = s.Id)
			WHERE u.Eliminado = 0 AND p.Eliminado = 0
			AND	u.Id = ANY (SELECT Id FROM @TOP_USUARIOS)
			ORDER BY Seguidores DESC
			FOR JSON PATH)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Usuarios no encontrados'
				SET @JSON_OUT = '{"Exito":false}'
			END
		

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
