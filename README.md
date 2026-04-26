

```markdown name=README.md url=https://github.com/VPaulC/AIBP_Suites/blob/9a49d5dddaec1d2bdd657c73ed869be2fb0b223b/README.md

# AIBP_Suites

**Configuration Scripts for MSP Service Implementation**

This project provides an example automation script to accelerate repeatable setup tasks for sub-300 seat customers. Always test in a lab tenant first, start in report-only modes where supported, and ensure proper validation before broad rollout.

---

## Appendix D: PowerShell Automation Guide

### D.1 Prerequisites

#### Software Requirements
- **PowerShell**: 7+ (recommended) or Windows PowerShell 5.1
- **Microsoft Graph PowerShell SDK**: Microsoft.Graph modules installed

#### Required Permissions
You will be prompted for delegated permissions. Minimum scopes required:

| Scope | Purpose |
|-------|---------|
| `Policy.ReadWrite.ConditionalAccess` | Create Conditional Access policies |
| `Group.ReadWrite.All` | Create groups |
| `Directory.Read.All` | Read directory objects |
| `Organization.Read.All` | Read subscribed SKUs |
| `Directory.ReadWrite.All` or `Group.ReadWrite.All` | Group-based licensing |

#### Tenant Prerequisites
- At least one break-glass account
- Pilot groups agreed upon
- Copilot licenses available (if assigning them)

---

### D.2 Script Capabilities

#### ✅ Can Do (Automated)
- Connect to Microsoft Graph with required scopes
- Create standard security groups (IT-Admins, Copilot-Pilot, Exceptions)
- Create Conditional Access policies (report-only by default):
  - Pilot MFA
  - Block legacy authentication
  - Pilot compliant-device access
  - Admin portal protection
- Assign Copilot licenses to pilot group via group-based licensing
- Defender evidence exports:
  - Secure Score
  - ORCA (MDO posture)
  - MDE machine inventory
- Defender for Office 365 (MDO) configuration (optional):
  - Enable Preset security policies
  - Safe Links & Safe Attachments
  - ZAP (pilot-first)
- Purview configuration (optional):
  - Create/update sensitivity labels
  - Publish labels to pilot scope
  - Create/update DLP policy (audit-first)
  - Export evidence
- Export configuration inventory for evidence/handover

#### ❌ Cannot Do (Manual or Separate Automation)
- Full Intune "policy-as-code" at scale (hundreds of settings)
- SharePoint/Teams permissions remediation at scale
- Tenant-wide baseline security mode settings (Secure Defaults)
- Anything that could risk tenant lockout
- Break-glass account modifications
- Existing policy removal

---

### D.3 PowerShell Script (Starter Automation)

*[Reference script location/details]*

---

### D.4 PowerShell Workflow, Prompts, and Post-Run Tasks

#### D.4.1 Pre-Run Checklist (Must Do)

- [ ] **Change Window**: Customer approval confirmed; pilot-first impacts understood
- [ ] **Break-Glass Accounts**: At least one UPN known; credentials secure; excluded from CA
- [ ] **Pilot Groups**: Display names confirmed for IT Admin, Copilot Pilot, Exceptions, and Pilot Devices
- [ ] **Licenses**: Business Premium + optional Defender/Purview/Copilot SKUs available
- [ ] **Workstation**: PowerShell as admin, Gallery access, TLS 1.2 enabled, interactive sign-in capable
- [ ] **Rollback Plan**: Documented approach to roll back changes

#### D.4.2 Execution Flow

| Step | Action |
|------|--------|
| 1 | Prompt collection: tenant hint, naming, break-glass UPNs, optional modules |
| 2 | Module installation: Graph SDK, ExchangeOnlineManagement, ORCA (if selected) |
| 3 | Authentication: Connect to Microsoft Graph with delegated scopes |
| 4 | Safety resolution: Resolve break-glass users; exclude from CA policies |
| 5 | Group creation: Create/reuse standard groups (IT-Admins, Copilot-Pilot, Exceptions) |
| 6 | Conditional Access baseline: Create 4 CA policies in Report-only mode |
| 7 | Intune baseline (optional): Create Windows compliance policy if pilot device group exists |
| 8 | Copilot licensing (optional): Group-based licensing for pilot group |
| 9 | Purview (optional): Create sensitivity labels, publish (pilot-first), create DLP (audit-first) |
| 10 | Defender for Office 365 (optional): Preset policies, Safe Links, Safe Attachments, ZAP |
| 11 | Defender evidence (optional): ORCA, Secure Score, MDE inventory |
| 12 | Evidence export: Write run summary and artifacts to Evidence folder |

#### D.4.3 Prompt Catalog

| Prompt | Controls | Guidance |
|--------|----------|----------|
| Tenant domain hint | Cosmetic (operator confirmation) | Optional. Use `customer.onmicrosoft.com` for sanity check |
| Group prefix | Naming for artifacts | Keep consistent across customers (e.g., `AI-Readiness`) |
| IT admins group name | Scope for CA04 admin protection | Use existing admin group or let script create |
| Copilot pilot group name | Scope for pilot CA + licensing | 10–30 real users; avoid "All Users" until validated |
| Exception users group name | CA02 exclusions | Keep empty unless documented business/technical exception |
| Pilot device group name | Intune baseline assignments | Use device group (not user group); skipped if not found |
| Break-glass UPNs (required) | CA exclusions for emergency | At least one; must be real cloud UPN, not shared accounts |
| Create Intune baseline? | Whether Intune objects are created | Yes only if Intune in scope + pilot device group ready |
| Attempt Copilot licensing? | License assignment to pilot | No if manual licensing or not purchased yet |
| Collect Defender evidence? | Exports Secure Score/ORCA/MDE | Recommended for baseline measurement |
| Configure Defender for Office 365? | MDO policies/Safe Links/Attachments | Yes only if licensed + pilot scope ready; start with Standard |
| Configure Purview? | Labels, publishing, DLP | Recommended if in scope; start small + Audit mode |
| DLP sensitive info types | What audit rule detects | Start narrow (Credit Card, Bank Account, Passport); expand later |

#### D.4.4 Expected Outputs (Evidence Files)

```
Evidence/
├── run-summary.json                                   # Choices and execution summary
├── groups.json                                        # Created/located groups
├── conditional-access-policies.json                   # All CA policies (report-only expected)
├── Intune/
│   └── created-intune-objects.json                   # Windows compliance policy, etc.
├── Security/
│   ├── secureScores.json                             # Secure Score snapshot
│   └── secureScoreControlProfiles.json               # Control catalog
├── ORCA/                                              # ORCA reports (HTML/CSV/JSON)
├── MDE/
│   ├── machines.json                                 # MDE inventory snapshot
│   └── machines-summary.csv                          # Summary export
├── MDO/                                               # Preset policy + Safe Links/Attachments
└── Purview/                                           # Labels, label policies, DLP policies
```

#### D.4.5 Troubleshooting (Common Issues)

| Issue | Solution |
|-------|----------|
| Module install fails (proxy/TLS) | Confirm TLS 1.2, Gallery access, admin rights. Configure proxy if needed. |
| Graph consent prompts | Sign in with account able to consent, or pre-consent via tenant admin. |
| "Pilot device group not found" | Verify correct display name; confirm it's a device group (not user group). Create first if needed. |
| Conditional Access policy exists | Script is idempotent by display name. Update manually or extend script to patch. |
| MDE inventory export fails | Defender for Endpoint API may need extra configuration. Treat as best-effort only. |
| Purview cmdlets unavailable | Confirm Security & Compliance PowerShell access and Compliance role assignment. |
| MDO cmdlets unavailable | Confirm Defender for Office 365 licensing and Exchange Online access. Use Defender UI if preset cmdlets fail. |

#### D.4.6 Post-Run Tasks

##### 1. Review & Archive Evidence
- Save Evidence folder to customer project repository
- Attach key exports to change record (Appendix B.1)

##### 2. Populate Groups
- **IT-Admins**: Add admins/operators
- **Copilot-Pilot**: Add pilot users
- **Pilot Device Group**: Add pilot devices
- **Exceptions**: Only add with documented business/technical reason

##### 3. Conditional Access: Report-Only Validation (24–72 hours)
- Review sign-in logs for impact and legacy auth attempts
- Confirm break-glass access remains possible (test in approved window)

##### 4. Conditional Access: Move to Enforced (On) in Waves
1. Start with **CA01** (MFA pilot)
2. Then **CA02** (legacy block)
3. Then **CA03** (compliant device for pilot)
4. Then **CA04** (admin portals)

Keep documented rollback: remove user from scope group or flip policy back to report-only/off

##### 5. Intune Baseline Completion
- Confirm devices enroll and become Compliant
- Deploy Endpoint security baselines from Intune portal (unless using approved JSON templates)
- Resolve policy conflicts (Settings catalog vs baselines) before broad rollout

##### 6. Defender for Office 365 Validation
- Confirm preset policies assigned to intended pilot users
- Confirm quarantine processes defined
- Validate Safe Links/Safe Attachments UX with benign test content (no malware)

##### 7. Purview Validation & Tuning
- Confirm labels appear in Office apps for pilot users
- Run DLP in Audit/Test mode; review alerts and false positives
- Refine sensitive info types, thresholds, and scope
- Move DLP to enforcement only after acceptance criteria met + comms/training delivered

##### 8. Copilot Readiness Checks
- Confirm pilot users are licensed and can access Copilot features
- Run permission boundary tests (Section 5.2.2)
- Record outcomes in Appendix B.2

##### 9. Update Documentation & Handover
- Update Appendix A (Handover checklist)
- Attach Evidence outputs
- Record all changes (scope, impact, rollback) in Appendix B.1
- Schedule customer IT handover walkthrough
- Confirm operating model alignment (Module 6)

---

**Last Updated**: 2026-04-26
```

## Key Improvements Made:

✅ **Hierarchical Structure**: Clear heading levels (H1–H4) for logical flow
✅ **Tables**: Replaced text lists with organized tables for prerequisites, execution flow, and prompts
✅ **Callout Sections**: Used checkboxes, emoji (✅❌), and visual separators
✅ **Better Navigation**: Consistent formatting and scannable sections
✅ **Evidence Structure**: ASCII tree showing output folder organization
✅ **Post-Run Tasks**: Numbered, bold, and clearly sequenced
✅ **Troubleshooting Table**: Easy reference for common issues
✅ **White Space**: Reduced density with strategic breaks and horizontal rules

Would you like me to push these changes to the repository?
