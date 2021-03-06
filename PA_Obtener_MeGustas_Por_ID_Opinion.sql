USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_MeGustas_Por_ID_Opinion]    Script Date: 15/06/2022 11:13:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve el numero de MG que tiene una opinion
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_MeGustas_Por_ID_Opinion]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'MG calculados'
		DECLARE @ID INT

		DECLARE @JSON_ELIMINADO NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @ID = Id
			FROM
				OPENJSON (@JSON_IN) WITH (Id INT '$.Id')
		-- Comrpobaciones de ese ID
		
		IF (@ID IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@ID = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@ID <0)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'ID menor que 0'
				SET @JSON_OUT = '{"Exito":false}'
			END



		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta

		SET @JSON_ELIMINADO = (
			SELECT id, Eliminado
			FROM Opinion o
			WHERE o.id = @ID
			FOR JSON PATH)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_ELIMINADO = '')
			BEGIN
				SET @RETCODE = 4
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_ELIMINADO IS NULL)
			BEGIN
				SET @RETCODE = 5
				SET @MENSAJE = 'Opinion no encontrada'
				SET @JSON_OUT = '{"Exito":false}'
			END
		ELSE
			BEGIN

				SELECT @ELIMINADO = Eliminado
					FROM
						OPENJSON (@JSON_ELIMINADO) WITH (Eliminado BIT '$.Eliminado')

				IF (@ELIMINADO = 1)
					BEGIN	

						SET @JSON_OUT = null
						SET @RETCODE = 6
						SET @MENSAJE = 'Opinion eliminado de forma logica'
						SET @JSON_OUT = '{"Exito":false}'

					END
				ELSE
					BEGIN
						
						SET @JSON_OUT = 
							(
								SELECT COUNT(Id_Usuario) AS 'Numero_Likes'
								FROM MeGusta
								WHERE Id_Opinion = @ID
							)

						IF (@JSON_OUT IS NULL)
							BEGIN
								SET @RETCODE = 7
								SET @MENSAJE = 'No se encontraron MeGustas'
								SET @JSON_OUT = '{"Exito":false}'
							END
					
					END
					

			END	

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
