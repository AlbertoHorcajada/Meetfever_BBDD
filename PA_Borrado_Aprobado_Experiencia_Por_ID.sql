USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Borrado_Aprobado_Experiencia_Por_ID]    Script Date: 15/06/2022 11:05:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Procedimiento Almacenado que hace un borrado logico de una experiencia a partid de un ID
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Borrado_Aprobado_Experiencia_Por_ID]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Experiencia a la espera de ser aprobada para su borrado.'
		DECLARE @ID INT
		DECLARE @JSONEXPERIENCIA NVARCHAR(MAX)
		DECLARE @IS_BORRADO_SOLICITADO NVARCHAR(MAX)
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @ID = Id
				FROM
					OPENJSON (@JSON_IN) WITH (Id INT '$.Id')

			-- Comrpobaciones de ese ID
		
			IF (@ID IS NULL)
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE = 'No llega el ID'
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

			-- Comprobar que de verdad existe el usuario y si es asi pasar todo a borrado logico

			SET @JSONEXPERIENCIA = (
			SELECT *
			FROM Experiencia
			WHERE Id = @ID
			FOR JSON PATH)

			IF (@JSONEXPERIENCIA IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'No existe la la Experiencia'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN

				SET @IS_BORRADO_SOLICITADO = (SELECT * FROM Experiencia WHERE id = @ID AND Borrado_Solicitado = 1 FOR JSON AUTO)

				IF(@IS_BORRADO_SOLICITADO IS NULL OR @IS_BORRADO_SOLICITADO = '')
					BEGIN
						UPDATE Experiencia SET Borrado_Solicitado = 1 WHERE Id = @ID
						SET @MENSAJE = 'Borrado solicitado activado.'
					END
				ELSE
					BEGIN
						UPDATE Experiencia SET Borrado_Solicitado = 0 WHERE Id = @ID
						SET @MENSAJE = 'Borrado solicitado desactivado.'
					END
							
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

