USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Actualizar_Opinion]    Script Date: 15/06/2022 11:05:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Actualiza una Opinion
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Actualizar_Opinion]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Opinion Actualizada'

		DECLARE @ID INT
		DECLARE @TITULO VARCHAR(30)
		DECLARE @DESCRIPCION NVARCHAR(300)
		DECLARE @FECHA DATETIME
		DECLARE @EMOTICONO INT
		DECLARE @ID_AUTOR INT
		DECLARE @ID_EMPRESA INT
		DECLARE @ID_EXPERIENCIA INT


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)

	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @ID = Id,
				@TITULO = Titulo, 
				@DESCRIPCION = Descripcion, 
				@FECHA = Fecha, 
				@EMOTICONO = Emoticono, 
				@ID_AUTOR = Id_Autor,
				@ID_EMPRESA = Id_Empresa,
				@ID_EXPERIENCIA = Id_Experiencia
				FROM
					OPENJSON (@JSON_IN) 
					WITH ( Id INT '$.Id',
					Titulo VARCHAR(30) '$.Titulo',
					Descripcion	NVARCHAR(300) '$.Descripcion',
					Fecha DATETIME '$.Fecha',
					Emoticono INT '$.Emoticono.Id',
					Id_Autor INT '$.Id_Autor',
					Id_Empresa INT '$.Id_Empresa',
					Id_Experiencia INT '$.Id_Experiencia')

			if(@TITULO IS NULL or @TITULO = '')
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE =  'Titulo vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF (@DESCRIPCION IS NULL or @DESCRIPCION = '')
				BEGIN
					SET @RETCODE = 2
					SET @RETCODE = 'Descripcion vacia'
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF(@FECHA IS NULL)
				BEGIN
					SET @RETCODE = 3
					SET @MENSAJE = 'Fecha vacia' 
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF(@EMOTICONO IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'Emoticono vacio' 
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF(@ID_AUTOR IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'Id_Autor vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE IF (@ID IS NULL)
				BEGIN
					SET @RETCODE = 5
					SET @MENSAJE = 'Id vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END
		
			IF(@RETCODE = 0)
			BEGIN
				SET @JSON_PRUEBA = (
				SELECT 
				e.Emoji
				FROM Emoticono e
				where e.Id = @EMOTICONO
				FOR JSON PATH)

				If (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
					BEGIN
						SET @RETCODE = 6
						SET @MENSAJE = 'Emoticono no existente'
						SET @JSON_OUT = '{"Exito":false}'
					END
				ELSE
					BEGIN
					SET @JSON_PRUEBA = (
						SELECT 
						u.Id
						FROM Usuario u
						where u.Id = @ID_AUTOR
					FOR JSON PATH)

					IF (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
						BEGIN
							SET @RETCODE = 7
							SET @MENSAJE = 'Usuario inexistente'
							SET @JSON_OUT = '{"Exito":false}'
						END
					END
				END


				IF (@RETCODE = 0)
					BEGIN
					 IF (@ID_EMPRESA IS NOT NULL AND @ID_EMPRESA > 0)
						BEGIN
						SET @JSON_PRUEBA = (
							SELECT 
							e.Id
							FROM Empresa e
							where e.Id = @ID_EMPRESA
						FOR JSON PATH)

						IF (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
							BEGIN
								SET @RETCODE = 8
								SET @MENSAJE = 'Empresa inexistente'
								SET @JSON_OUT = '{"Exito":false}'
							END
						END
						ELSE
								BEGIN
									SET @ID_EMPRESA = NULL
								END
					END

				IF (@RETCODE = 0)
					BEGIN	
					 IF(@ID_EXPERIENCIA IS NOT NULL AND @ID_EXPERIENCIA >0)
							BEGIN
							SET @JSON_PRUEBA = (
								SELECT 
								e.Id
								FROM Experiencia e
								WHERE e.Id = @ID_EXPERIENCIA
							FOR JSON PATH)

							IF (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
								BEGIN
									SET @RETCODE = 9
									SET @MENSAJE = 'Experiencia inexistente'
									SET @JSON_OUT = '{"Exito":false}'
								END
							END
							ELSE
								BEGIN
									SET @ID_EXPERIENCIA = NULL
								END
						END
					
				
			IF(@RETCODE = 0)
			BEGIN
				SET @JSON_PRUEBA = (
				SELECT 
				o.Id
				FROM Opinion o
				where o.Id = @ID AND Eliminado = 0
				FOR JSON PATH)

				If (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
					BEGIN
						SET @RETCODE = 10
						SET @MENSAJE = 'Opinion inexistente o eliminado de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END
			END
		

			SET NOCOUNT ON;

			if (@RETCODE = 0)
				BEGIN
					UPDATE opinion
						SET
							Titulo = @TITULO, 
							Descripcion = @DESCRIPCION, 
							Fecha = @FECHA, 
							Emoticono = @EMOTICONO, 
							Id_Autor = @ID_AUTOR, 
							Id_Empresa = @ID_EMPRESA, 
							Id_Experiencia = @ID_EXPERIENCIA,
							Eliminado = 0
						WHERE id = @ID 
			
					SET @JSON_OUT = '{"Exito":true}'
				END
			ELSE
				BEGIN
					SET @JSON_OUT = '{"Exito":false}'
				END
		
		

		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH
		