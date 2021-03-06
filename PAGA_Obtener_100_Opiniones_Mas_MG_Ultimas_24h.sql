USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PAGA_Obtener_100_Opiniones_Mas_MG_Ultimas_24h]    Script Date: 15/06/2022 11:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Gonzalo Racero Galán y Alberto Horcajada
-- Create date: 27/04/2022
-- Descrption:	Obtener las 100 opiniones con mas me gusta de las últimas 24 horas.
-- ============================================

--ESTA VERSIÓN SOLO DEVUELVE IDS
ALTER PROCEDURE [dbo].[PAGA_Obtener_100_Opiniones_Mas_MG_Ultimas_24h]
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT
	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Encontradas las 100 opiniones con mas me gustas de las últimas 24h.'

		DECLARE @TOP_OPINIONES TABLE (Id INT)
		DECLARE @ID INT 

	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @ID = Id_Usuario
					FROM
						OPENJSON (@JSON_IN) 
						WITH (Id_Usuario INT '$.Id_Usuario')

			-- TU MISION ES OBTENER LAS 100 PRIMERAS OPINIONES CON MAS MG DE LAS ÚLTIMAS 24 HORAS
				-- YO DEVUELVO LAS 100 PRIMERAS QUE PILLE DE MOMENTO PARA PODER TRABAJAR EN LA APP DEL MOVIL
				-- SI ME LA QUITO DE ENCIMA TE HECHO UNA MANO :D
				-- SI HAY MENOS DE 100 QUE CUMPLAN ESOS REQUISITOS DEVUELVO LAS QUE HAY

				if(@ID IS NULL OR @ID = '')
					BEGIN
					
						SELECT @ID = Id_Usuario
								FROM
									OPENJSON (@JSON_IN) 
									WITH (Id_Usuario INT '$.Id')
					END
				

				IF (@ID IS NULL)
					BEGIN
						SET @RETCODE = 1
						SET @MENSAJE = 'No hay Id del Usuario' + ' | ' + @JSON_IN 
						SET @JSON_OUT = '{"Exito":false}'
					END

				SET NOCOUNT ON;
	
			INSERT INTO @TOP_OPINIONES 
				SELECT TOP 100 o.Id
					FROM  Opinion o LEFT JOIN MeGusta m
					ON (m.Id_Opinion = o.Id)
					WHERE o.Eliminado = 0  --AND DATEDIFF (SECOND, o.Fecha ,DATEADD(DAY,-1,CURRENT_TIMESTAMP)) < 0  
					GROUP BY (o.Id)
					ORDER BY (COUNT(m.Id_Usuario)) DESC
	
				

				IF (@RETCODE = 0)
					BEGIN

						SET @JSON_OUT = (
			
							SELECT DISTINCT o.Id,
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
							CAST(
							 CASE
								  WHEN ((select id from MeGusta mg WHERE mg.Id_Usuario = @ID AND mg.Id_Opinion = o.Id) IS NULL)
									 THEN 0
								  ELSE 1
							 END AS bit)
							 AS 'Like',
							 (select COUNT(distinct mg.Id_Usuario) from MeGusta mg where mg.Id_Opinion = o.Id) AS 'Numero_Likes'
							FROM Opinion o INNER JOIN Usuario u ON (U.Id = o.Id_Autor)
								INNER JOIN Emoticono e ON (e.Id = o.Emoticono)
							WHERE o.Eliminado = 0 
								AND o.Id = ANY (select id from @TOP_OPINIONES)
							ORDER BY 'Numero_Likes' DESC
							FOR JSON PATH)

							IF (@JSON_OUT IS NULL)
								BEGIN
									SET @RETCODE = 0
									SET @MENSAJE = 'Algo salio mal'
									SET @JSON_OUT = '{"Exito":false}'
								END

					END
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		ROLLBACK TRANSACTION
	END CATCH
