USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Opinion]    Script Date: 15/06/2022 11:10:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta una Opinion
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Opinion]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Opinion insertada'


		DECLARE @TITULO VARCHAR(30)
		DECLARE @DESCRIPCION NVARCHAR(300)
		DECLARE @FECHA DATETIME
		DECLARE @EMOTICONO INT
		DECLARE @ID_AUTOR INT
		DECLARE @ID_EMPRESA INT = NULL
		DECLARE @ID_EXPERIENCIA INT = NULL


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		SELECT @TITULO = Titulo, 
			@DESCRIPCION = Descripcion, 
			@FECHA = Fecha, 
			@EMOTICONO = Emoticono, 
			@ID_AUTOR = Id_Autor,
			@ID_EMPRESA = Id_Empresa,
			@ID_EXPERIENCIA = Id_Experiencia
			FROM
				OPENJSON (@JSON_IN) 
				WITH (Titulo VARCHAR(30) '$.Titulo',
				Descripcion	NVARCHAR(300) '$.Descripcion',
				Fecha DATETIME '$.Fecha',
				Emoticono INT '$.Id_Emoticono',
				Id_Autor INT '$.Id_Autor',
				Id_Empresa INT '$.Id_Empresa',
				Id_Experiencia INT '$.Id_Experiencia')



		-- Comprobaciones de que los campos obligatorios tienen informacion

		if(@TITULO IS NULL)
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
				SET @RETCODE = 5
				SET @MENSAJE = 'Autor vacio' 
				SET @JSON_OUT = '{"Exito":false}'
			END
		
			

		-- comprobar que las fk existen

			-- Comprobar que existe el emoticono
		IF(@RETCODE = 0)
		BEGIN
			SET @JSON_PRUEBA = (
			SELECT 
			e.Emoji
			FROM Emoticono e
			where e.Id = @EMOTICONO and e.Eliminado = 0
			FOR JSON PATH)

			If (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
				BEGIN
					SET @RETCODE = 6
					SET @MENSAJE = 'Emoticono inexistente o eliminado de forma logica'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN
			-- comprobar que existe el autor	
				SET @JSON_PRUEBA = (
					SELECT 
					u.Id
					FROM Usuario u
					where u.Id = @ID_AUTOR and u.Eliminado = 0
				FOR JSON PATH)

				IF (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
					BEGIN
						SET @RETCODE = 7
						SET @MENSAJE = 'Usuario inexistente o borrado de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END
				END
			END

			-- Comprobar si tienen referencia a empresa o experiencia al ser voluntarios, en caso de tenerlas compruebo que existan

			IF (@RETCODE = 0)
				BEGIN
				-- Si la empresa no es nula, indica que me ha pasado alguna
				 IF (@ID_EMPRESA IS NOT NULL)
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
				END	

			IF (@RETCODE = 0)
				BEGIN	
				 IF(@ID_EXPERIENCIA IS NOT NULL)
						BEGIN
				-- Comprobar CIF de la empresa
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
							--Cierro else despues de nombre empresa
						END
						-- cierro else depues nick
					END
					
				
		
		

		SET NOCOUNT ON;

		-- Buscar en la BBDD el Usuario por ID y crear el JSON
		if (@RETCODE = 0)
			BEGIN
				insert into opinion(
					Titulo, 
					Descripcion, 
					Fecha, 
					Emoticono , 
					Id_Autor, 
					Id_Empresa, 
					Id_Experiencia, 
					Eliminado) 
				values 
					(@TITULO, 
					@DESCRIPCION, 
					@FECHA,
					@EMOTICONO, 
					@ID_AUTOR, 
					@ID_EMPRESA, 
					@ID_EXPERIENCIA, 
					0)
			
				SET @JSON_OUT = '{"Exito":true}'

			END
		ELSE
			BEGIN
				SET @JSON_OUT = '{"Exito":false}'
			END

		
		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
		