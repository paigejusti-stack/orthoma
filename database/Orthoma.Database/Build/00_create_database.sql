/*  Orthoma star-schema build - 00 Create database
    ------------------------------------------------------------------
    Creates the target database 'ortho'. Run this first.
    Idempotent: does nothing if 'ortho' already exists.
*/
IF DB_ID('ortho') IS NULL
    CREATE DATABASE ortho;
GO
