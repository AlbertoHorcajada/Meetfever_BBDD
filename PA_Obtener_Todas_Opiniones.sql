USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Todas_Opiniones]    Script Date: 15/06/2022 11:18:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve el top 100 opiniones sin borrado logico ordenadas por numero de MG
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Todas_Opiniones]
	
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'opiniones devueltas'

		DECLARE @TOP_OPINIONES TABLE (Id INT)

		

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SET NOCOUNT ON;
		
		INSERT INTO @TOP_OPINIONES 
		SELECT TOP 100 o.Id
			FROM MeGusta m RIGHT JOIN Opinion o
			ON (m.Id_Opinion = o.Id)
			WHERE o.Eliminado = 0
			GROUP BY (o.Id)
			order by count(o.Id) desc
		
		-- Crear JSON de respuesta a raiz de la consulta

		SET @JSON_OUT = (
			
			SELECT o.Id,
			o.Titulo,
			o.Descripcion,
			o.Fecha,
			-- solo el genérico porque el 95% de los casos no necesito al hijo
			u.id AS 'Autor.Id',
			u.Correo AS 'Autor.Correo',
			u.Contrasena AS 'Autor.Contrasena',
			u.Nick AS 'Autor.Nick',
			u.Foto_Fondo AS 'Autor.Foto_Fondo',
			u.Foto_Perfil AS 'Autor.Foto_Perfil',
			u.Telefono AS 'Autor.Telefono',
			u.Frase AS 'Autor.Frase',
			o.Id_Empresa,
			o.Id_Experiencia, -- importante el emoji
			e.Id AS 'Emoticono.Id',
			e.Emoji AS 'Emoticono.Emoji',
			 (select COUNT(distinct mg.Id_Usuario) from MeGusta mg where mg.Id_Opinion = o.Id) AS 'Numero_Likes'
			FROM Opinion o INNER JOIN Usuario u  ON (U.Id = o.Id_Autor)
				INNER JOIN Emoticono e ON (e.Id = o.Emoticono)
			WHERE o.Eliminado = 0
				AND o.Id = ANY (SELECT Id FROM @TOP_OPINIONES)
			ORDER BY Numero_Likes DESC
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
				SET @MENSAJE = 'opiniones no encontradas'
				SET @JSON_OUT = '{"Exito":false}'
			END
		

		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
