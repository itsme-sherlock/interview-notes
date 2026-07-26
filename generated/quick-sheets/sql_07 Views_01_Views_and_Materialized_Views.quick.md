# Quick Sheet: sql\07 Views\01_Views_and_Materialized_Views.md

<!-- QUICK_SHEET_START -->

## Quick Sheet
- Source: sql\07 Views\01_Views_and_Materialized_Views.md
- Blocks captured: 1


## Quick Sheet
- View: virtual table storing query text.
- Materialized view: physical data snapshot with refresh strategy.
- Simple view is usually updatable; complex view often needs `INSTEAD OF` trigger.
- `WITH CHECK OPTION`: enforce view filter for DML through the view.
- `WITH READ ONLY`: block DML through the view.


<!-- QUICK_SHEET_END -->

## Table of Contents
- [Main Content](#main-content)

## Main Content

