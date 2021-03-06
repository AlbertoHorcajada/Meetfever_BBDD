USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Borrado_Real_seguidor_Por_ID]    Script Date: 15/06/2022 11:07:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Procedimiento almacenado encargado de hacer un borrado real de la relacion de un usuario con otro, "dejar de seguir"
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Borrado_Real_seguidor_Por_ID]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Seguidor Eliminado'
		DECLARE @IDSEGUIDOR INT
		DECLARE @IDSEGUIDO INT
		DECLARE @JSONSEGUIDO NVARCHAR(MAX)
		DECLARE @JSONSEGUIDOR NVARCHAR(MAX)
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @IDSEGUIDOR = Seguidor
				FROM
					OPENJSON (@JSON_IN) WITH (Seguidor INT '$.Seguidor')

			SELECT @IDSEGUIDO = Seguido
				FROM
					OPENJSON (@JSON_IN) WITH (Seguido INT '$.Seguido')
			-- Comrpobaciones de ese ID
		
			IF (@IDSEGUIDO IS NULL OR @IDSEGUIDOR IS NULL)
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE = 'No llega uno de los ID'
					SET @JSON_OUT = '{"Exito":false}'
				END

			IF (@IDSEGUIDO = '' OR @IDSEGUIDO = '')
				BEGIN
					SET @RETCODE = 2
					SET @MENSAJE = 'Algun ID o Ambos estan vacios'
					SET @JSON_OUT = '{"Exito":false}'
				END

			IF (@IDSEGUIDO <0 OR @IDSEGUIDOR <0)
				BEGIN
					SET @RETCODE = 3
					SET @MENSAJE = 'Alguno o ambos ID son menores que 0'
					SET @JSON_OUT = '{"Exito":false}'
				END

			SET NOCOUNT ON;

			-- Comprobar que de verdad existe la relacion y si es asi elimiarla

			SET @JSONSEGUIDO = (
			SELECT *
			FROM Usuario
			WHERE Id = @IDSEGUIDO
			FOR JSON PATH)

			SET @JSONSEGUIDOR = (
			SELECT *
			FROM Usuario
			WHERE Id = @IDSEGUIDOR
			FOR JSON PATH)

			IF (@JSONSEGUIDO IS NULL OR @JSONSEGUIDOR IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'No existe alguno o ambos de los usuarios'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN
				
					DELETE FROM Seguidor_Seguido 
						WHERE Seguidor = @IDSEGUIDO AND Seguido = @IDSEGUIDO

						SET @JSON_OUT = '{"Exito":true}'
				END
				
			COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH

