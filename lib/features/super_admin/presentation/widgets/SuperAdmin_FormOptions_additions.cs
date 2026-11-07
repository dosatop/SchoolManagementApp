// ====================================================================
// FORM OPTIONS — departments, trades and trade subjects for the
// "Add student" form.  GET api/super-admin/schools/{schoolId}/options
// ====================================================================

// --------------------------------------------------------------------
// 1. ISuperAdminService.cs — add inside the interface
// --------------------------------------------------------------------

    Task<SuperAdminResult> GetSchoolFormOptionsAsync(Guid schoolId);


// --------------------------------------------------------------------
// 2. SuperAdminService.cs — add anywhere inside the class
// --------------------------------------------------------------------

    public async Task<SuperAdminResult> GetSchoolFormOptionsAsync(Guid schoolId)
    {
        if (!await SchoolExists(schoolId))
            return SuperAdminResult.Missing("School not found.");

        var departments = await _context.Departments
            .AsNoTracking()
            .Where(d => d.SchoolId == schoolId)
            .OrderBy(d => d.Name)
            .Select(d => new { departmentId = d.Id, departmentName = d.Name })
            .ToListAsync();

        var tradeSubjects = await _context.Subjects
            .AsNoTracking()
            .Where(s => s.SchoolId == schoolId && s.TradeId != null)
            .OrderBy(s => s.Name)
            .Select(s => new { subjectId = s.Id, subjectName = s.Name, s.TradeId })
            .ToListAsync();

        var trades = await _context.Trades
            .AsNoTracking()
            .Where(t => t.SchoolId == schoolId)
            .OrderBy(t => t.Name)
            .Select(t => new { t.Id, t.Name })
            .ToListAsync();

        return SuperAdminResult.Ok(new
        {
            departments,
            trades = trades.Select(t => new
            {
                tradeId = t.Id,
                tradeName = t.Name,
                subjects = tradeSubjects
                    .Where(s => s.TradeId == t.Id)
                    .Select(s => new { s.subjectId, s.subjectName })
                    .ToList()
            })
        });
    }


// --------------------------------------------------------------------
// 3. SuperAdminController.cs — add with the other actions
// --------------------------------------------------------------------

    [HttpGet("options")]
    public async Task<IActionResult> GetSchoolFormOptions(Guid schoolId) =>
        ToResponse(await _service.GetSchoolFormOptionsAsync(schoolId));
