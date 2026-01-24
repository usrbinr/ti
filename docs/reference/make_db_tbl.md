# Make an in memory database from a table

Ensures the input is a database-backed object. If a data.frame is
provided, it is registered into a temporary, in-memory DuckDB instance.
If already a `tbl_dbi`, it is returned unchanged.

## Usage

``` r
make_db_tbl(x)
```

## Arguments

- x:

  A tibble, data.frame, or tbl_dbi object.

## Value

dbi object

A `tbl_dbi` object backed by DuckDB.

## Details

When converting a data.frame, this function preserves existing `dplyr`
groups. It uses DuckDB's `duckdb_register`, which is a virtual
registration and does not perform a physical copy of the data, making it
extremely fast.
