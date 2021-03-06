USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PAGA_Todas_Personas_Que_Quizas_Conozca]    Script Date: 15/06/2022 11:23:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Gonzalo Racero Galán y Alberto Horcajada
-- Create date: 23/04/2022
-- Descrption:	A partir de una id de usuario, obtener los seguidores que no sigo de mis seguidores y mis seguidos
-- ============================================

	ALTER PROCEDURE [dbo].[PAGA_Todas_Personas_Que_Quizas_Conozca]
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT
	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Personas que quizás conozcas encontradas exitosamente.'
		DECLARE @Id INT
		DECLARE @JSON_PRUEBA NVARCHAR(MAX)

		DECLARE @MIS_SEGUIDORES TABLE (
			Id INT
		)

		DECLARE @MIS_SEGUIDOS TABLE (
			Id INT
		)

		DECLARE @MIS_SEGUIDORES_Y_SEGUIDOS TABLE (
			Id INT
		)

		DECLARE @SEGUIDORES_DE_MIS_SEGUIDORES_Y_SEGUIDOS TABLE (
			Id INT
		)

		DECLARE @SEGUIDOS_DE_MIS_SEGUIDORES_Y_SEGUIDOS TABLE (
			Id INT
		)

		DECLARE @SEGUIDORES_Y_SEGUIDOS_DE_MIS_SEGUIDORES_Y_SEGUIDOS TABLE (
			Id INT
		)


	BEGIN TRY

	-- OBTENGO LA ID DEL TIO QUE QUIERO VER SUS SEGUIDORES Y SEGUIDOS
		SELECT @Id = Id
			FROM
				OPENJSON (@JSON_IN) WITH (Id INT '$.Id')
	
		-- Verificaciones de datos de entrada.
		IF (@Id IS NULL OR @Id = '')
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Identificador de la persona erroneo.'
			END

		SET @JSON_PRUEBA = (
			SELECT Id FROM Usuario WHERE Id = @Id AND Eliminado = 0 FOR JSON AUTO
		)

		IF (@JSON_PRUEBA IS NULL)
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Usuario no encontrado o borrado de forma logica'
			END

		SET NOCOUNT ON;

		-- AQUI HAY QUE OBTENER LAS PERSONAS QUE SIGUEN LOS QUE YO SIGO
		-- Y LAS PERSONAS QUE SIGUEN LOS QUE ME SIGUEN

		-- MENOS AQUELLOS QUE YO YA SIGA 

		-- DE MOMENTO ME HAGO UN PA QUE ME DEVUELVA 10 PERSONAS RANDOM, YA VEREMOS JUNTOS ESA QUERY
		-- QUE NO SE POR DONDE COGERLA -> FDO GONZALO OwO

				-- CONSIGO A LOS QUE SIGO:

INSERT INTO @MIS_SEGUIDORES 
				SELECT DISTINCT s.seguidor
					FROM Seguidor_Seguido s INNER JOIN Usuario u
					ON (u.Id = s.Seguidor)
					WHERE u.Eliminado = 0 AND s.Seguido = @Id
					GROUP BY (s.Seguidor)

		-- OBTENGO SUS SEGUIDORES
		INSERT INTO @MIS_SEGUIDOS 
				SELECT DISTINCT s.seguido
					FROM Seguidor_Seguido s INNER JOIN Usuario u
					ON (u.Id = s.Seguido)
					WHERE u.Eliminado = 0 AND s.Seguidor = @Id
					GROUP BY (s.Seguido)
		-- OBTENGO TODOS
		INSERT INTO @MIS_SEGUIDORES_Y_SEGUIDOS 
				SELECT DISTINCT u.id	
					FROM Usuario u
					WHERE id IN (select id from @MIS_SEGUIDORES) OR id IN (select id from @MIS_SEGUIDOS)

		-- OBTENER SEGUIDORES DE @MIS..

		INSERT INTO @SEGUIDORES_DE_MIS_SEGUIDORES_Y_SEGUIDOS 
				SELECT DISTINCT s.seguidor
					FROM Seguidor_Seguido s INNER JOIN Usuario u
					ON (u.Id = s.Seguidor)
					WHERE u.Eliminado = 0 AND s.Seguido = ANY (SELECT id FROM @MIS_SEGUIDORES_Y_SEGUIDOS)
					GROUP BY (s.Seguidor)

		-- OBTENER SEGUIDOS DE @MIS...

		INSERT INTO @SEGUIDOS_DE_MIS_SEGUIDORES_Y_SEGUIDOS 
				SELECT DISTINCT s.seguido
					FROM Seguidor_Seguido s INNER JOIN Usuario u
					ON (u.Id = s.Seguido)
					WHERE u.Eliminado = 0 AND s.Seguidor = ANY (SELECT id FROM @MIS_SEGUIDORES_Y_SEGUIDOS)
					GROUP BY (s.Seguido)

		--SELECCIONAR TODOS DE FORMA DISTINTA

			INSERT INTO @SEGUIDORES_Y_SEGUIDOS_DE_MIS_SEGUIDORES_Y_SEGUIDOS 
				SELECT DISTINCT u.id	
					FROM Usuario u
					WHERE id IN (select id from @MIS_SEGUIDORES_Y_SEGUIDOS) OR id = any (select id from @SEGUIDOS_DE_MIS_SEGUIDORES_Y_SEGUIDOS)


		SET @JSON_OUT = ( 
					SELECT TOP 100  
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
						SEXO.Sexo AS 'Sexo.Sexo'
					FROM USUARIO INNER JOIN PERSONA
							ON (Usuario.Id = PERSONA.Id)
						INNER JOIN SEXO 
							ON (SEXO.Id = Persona.Sexo)
					WHERE USUARIO.Eliminado = 0  AND PERSONA.Eliminado = 0
						AND Usuario.Id = ANY (Select id from @SEGUIDORES_Y_SEGUIDOS_DE_MIS_SEGUIDORES_Y_SEGUIDOS) 
						AND Usuario.Id NOT IN (select id from @MIS_SEGUIDOS)
						AND Usuario.Id != @Id
				FOR JSON PATH)  

		IF (@JSON_OUT IS NULL)
		BEGIN
			SET @RETCODE = 3
			SET @MENSAJE = 'No hay personas recomendadas para ese usuario.'
		END

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
	END CATCH
