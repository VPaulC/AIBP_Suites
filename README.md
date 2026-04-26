# AIBP_Suites
Configuration Scripts for MSP service implementation
provides an example automation script to accelerate repeatable setup tasks for sub 300-seat customers. Always test in a lab tenant first, start in report-only modes where supported, and ensure you have break-glass accounts in place before enabling any access policies.
D.1 Prerequisites
•	PowerShell 7+ recommended, or Windows PowerShell 5.1.
•	Microsoft Graph PowerShell SDK installed: Microsoft.Graph modules.
•	Permissions: you will be prompted for delegated permissions. Minimum scopes used by this script are typically:
o	Policy.ReadWrite.ConditionalAccess (create Conditional Access policies)
o	Group.ReadWrite.All (create groups)
o	Directory.Read.All (read directory objects)
o	Organization.Read.All (read subscribed SKUs)
o	Directory.ReadWrite.All or Group.ReadWrite.All (group-based licensing)
•	Tenant prerequisites: at least one break-glass account; pilot groups agreed; Copilot licences available if you intend to assign them.
D.2 What this script can and cannot do
Can do (automated)	Cannot do / not included (manual or separate automation)
•	Connect to Microsoft Graph with required scopes.
•	Create standard security groups used by this runbook (IT-Admins, Copilot-Pilot, Exceptions).
•	Create Conditional Access policies (pilot MFA; block legacy authentication; pilot compliant-device access; admin portal protection) in report-only by default.
•	Assign Copilot licences to a pilot group using group-based licensing (if available).
•	Defender evidence exports: Secure Score, ORCA (MDO posture), MDE machine inventory export.
•	Defender for Office 365 (MDO) configuration (optional, gated): enable Preset security policies + Safe Links + Safe Attachments + ZAP (pilot-first).
•	Purview configuration (optional, gated): create/update sensitivity labels; publish labels to a pilot scope; create/update DLP policy (audit-first) and export evidence.
•	Export a configuration inventory (groups, CA policies, Defender/Purview artefacts where created) for evidence/handover.	•	Full Intune “policy-as-code” at scale (hundreds of settings, multiple platforms, version control, and CI/CD). The script can create a basic SMB baseline (pilot-scoped) but complex estates should use a dedicated, versioned Intune configuration project.
•	SharePoint/Teams permissions remediation at scale (site-by-site oversharing fixes are customer-specific).
•	Tenant-wide baseline security mode settings (Secure Defaults / Baseline security mode) are tenant/UI-driven; script exports evidence but does not toggle these by default.
•	Anything that could risk tenant lockout (script will not modify break-glass accounts or remove existing policies).
D.3 PowerShell script (starter automation)
D.4 PowerShell workflow, prompts, and post-run tasks
Use this section as the operator guide for running the starter automation script in Appendix D.3. It explains the end-to-end workflow (what happens in what order), lists every prompt the script will ask, provides guidance on how to respond (and when to choose “No”), and finishes with the manual tasks required to complete the implementation and validate outcomes.
D.4.1 Pre-run checklist (must do)
•	Change window approved: confirm the customer has approved the window and understands pilot-first impacts (MFA, device compliance, Safe Links/Safe Attachments, labelling prompts, DLP policy tips).
•	Break-glass accounts confirmed: at least one break-glass UPN is known, credentials stored securely, and excluded from Conditional Access (with monitoring and strong passwords).
•	Pilot groups agreed: confirm display names for IT admin group, Copilot pilot users group, exception users group, and a pilot device group for Intune assignments.
•	Licences available: Business Premium licences assigned as baseline; optional Defender/Purview/Copilot SKUs available if you intend to configure/assign them.
•	Workstation readiness: run PowerShell as administrator; outbound access to PowerShell Gallery; TLS 1.2 enabled; able to sign in interactively for Graph and (optionally) Exchange Online / Compliance PowerShell.
•	Rollback plan: confirm how to roll back (remove users from pilot groups, disable a specific policy, or revert a single Intune policy assignment).
D.4.2 Execution flow (what the script does, in order)
1.	Prompt collection: gathers tenant hint, naming, break-glass UPNs, and which optional modules you want to run (Intune, Copilot licensing, Defender evidence, Defender for Office 365 config, Purview labels/DLP).
2.	Module installation: installs/loads required PowerShell modules (Graph SDK modules, and ExchangeOnlineManagement/ORCA if selected).
3.	Authentication: connects to Microsoft Graph with the minimum required delegated scopes; additional sign-ins occur only if you enabled Exchange Online / Compliance PowerShell actions.
4.	Safety resolution: resolves break-glass user object IDs to ensure they’re excluded from Conditional Access policies.
5.	Group creation: creates (or reuses) the standard groups used by this runbook (IT-Admins, Copilot-Pilot, Exceptions). Optionally resolves the pilot device group for Intune assignments.
6.	Conditional Access baseline: creates the four baseline CA policies in Report-only (MFA pilot, block legacy auth, require compliant device for Office 365, admin portal MFA). Nothing is enforced automatically.
7.	Intune baseline (optional): if enabled and the pilot device group exists, creates a Windows compliance policy and assigns it to the pilot device group. (Endpoint security policies may require tenant-approved templates if you extend the script.)
8.	Copilot licensing (optional): attempts group-based licensing for the pilot group using the Copilot SKU part number hint (skips if not found).
9.	Purview (optional): connects to Security & Compliance PowerShell to create/update sensitivity labels, publish labels (pilot-first), and create/update a DLP policy (audit-first) using your selected sensitive info types.
10.	Defender for Office 365 (optional): connects to Exchange Online to enable preset security policies and/or create Safe Links/Safe Attachments policies and rules (pilot-first), plus ZAP best-effort enablement.
11.	Defender evidence (optional): runs ORCA (if selected), exports Secure Score JSON, and exports an MDE machine inventory snapshot.
12.	Evidence export: writes run summary and artefact exports to the Evidence folder for handover.
D.4.3 Prompt catalogue (what you’ll be asked, and how to answer)
Prompt / input	What it controls	Guidance / recommended response
Tenant domain hint	Cosmetic only (helps operator confirm tenant)	Optional. Enter customer.onmicrosoft.com if you want an extra sanity check in logs.
Group prefix	Naming for created artefacts	Keep consistent across customers (e.g., AI-Readiness), or include customer shorthand if you manage multiple tenants.
IT admins group name	Scope for CA04 admin portal protection	Use an existing admin group if the customer already has one; otherwise let the script create it and then add admins.
Copilot pilot group name	Scope for pilot CA + optional licensing	Use a real pilot group containing 10–30 users; avoid “All Users” until validation is complete.
Exception users group name	Exclusions from CA02 (and future exceptions)	Keep this group empty unless you have a documented business/technical exception.
Pilot device group name	Assignments for Intune baseline	Recommended. Use a device group (not user group). If blank or not found, Intune assignments are skipped.
Break-glass UPNs (required)	CA exclusions for emergency access	Enter at least one. Must be a real cloud user UPN. Do not use shared admin accounts.
Create Intune baseline?	Whether Intune objects are created/assigned	Choose Yes only if Intune is in scope and you have a pilot device group ready.
Attempt Copilot group-based licensing?	Licence assignment to pilot group	Choose No if the customer assigns licences manually, or if Copilot is not purchased yet.
Collect Defender evidence?	Exports Secure Score/ORCA/MDE inventory	Recommended for evidence and baseline measurement, even if you are not enforcing changes yet.
Configure Defender for Office 365 policies?	MDO preset policies / Safe Links / Safe Attachments / ZAP	Choose Yes only if Defender for Office 365 is licensed and you have a pilot scope. Start with Standard preset for pilot users.
Configure Purview (labels + DLP)?	Creates labels/publishing and audit-first DLP	Recommended if Purview is in scope. Start with a small label set and DLP in Audit mode with policy tips.
DLP sensitive info types	What the audit rule detects	Use a narrow set initially (e.g., “Credit Card Number”, “Bank Account Number”, “Passport Number”) and expand once you understand alert volume.
D.4.4 Expected outputs (evidence files)
•	Evidence\run-summary.json — Single JSON summary of what you chose and what ran.
•	Evidence\groups.json — Groups created/located by prefix.
•	Evidence\conditional-access-policies.json — All CA policies with state (expect report-only for the ones created by the script).
•	Evidence\Intune\created-intune-objects.json — Intune objects created (at minimum the Windows compliance policy if enabled).
•	Evidence\Security\secureScores.json and secureScoreControlProfiles.json — Secure Score snapshot and control catalogue (if enabled).
•	Evidence\ORCA\ — ORCA report outputs (HTML/CSV/JSON depending on module version) (if enabled).
•	Evidence\MDE\machines.json and machines-summary.csv — MDE inventory snapshot (if enabled and API access succeeds).
•	Evidence\MDO\ — Preset policy + Safe Links/Safe Attachments policy/rule exports (if enabled).
•	Evidence\Purview\ — Labels, label policies, DLP policies and rules exports (if enabled).
D.4.5 Troubleshooting (common issues)
•	Module install fails (proxy/TLS): confirm TLS 1.2, outbound access to PowerShell Gallery, and run as administrator. If a corporate proxy is required, configure it for PowerShell and retry.
•	Graph consent prompts: ensure you sign in with an account that can consent to the requested delegated scopes (or pre-consent via tenant admin workflows).
•	“Pilot device group not found”: confirm you entered the correct display name and that it is a device group (and not a user group). Create it first if needed.
•	Conditional Access policy exists: the script is idempotent for CA display names; if you need to change policy settings, update the existing policy manually or extend the script to patch the policy.
•	MDE inventory export fails: Defender for Endpoint API access may require additional tenant configuration/permissions. Treat this export as best-effort evidence only.
•	Purview cmdlets unavailable: confirm you can connect to Security & Compliance PowerShell (Connect-IPPSSession) and that the signed-in account has appropriate Compliance roles.
•	MDO cmdlets unavailable: confirm Defender for Office 365 licensing and Exchange Online PowerShell access; if preset policy cmdlets fail, use the Defender portal preset policies UI for that tenant.
D.4.6 Post-run tasks (to complete the implementation)
1.	Review evidence outputs: save the Evidence folder to the customer project repository and attach key exports to the change record (Appendix B.1).
2.	Populate groups: add the right users/devices to:
o	IT-Admins (admins/operators)
o	Copilot-Pilot (pilot users)
o	Pilot device group (pilot devices)
o	Exceptions (only when documented)
3.	Conditional Access: validate in Report-only (24–72 hours recommended):
o	Review sign-in logs for impact and legacy auth attempts.
o	Confirm break-glass access remains possible (test in the approved window).
4.	Conditional Access: move to Enforced (On) in waves:
o	Start with CA01 (MFA pilot), then CA02 (legacy block), then CA03 (compliant device for pilot), then CA04 (admin portals).
o	Keep a documented rollback: remove a user from scope group or flip a single policy back to report-only/off.
5.	Intune baseline completion:
o	Confirm devices enrol and become Compliant.
o	Deploy Endpoint security baselines (Windows security baseline, Defender for Endpoint baseline) from the Intune portal, unless you have approved JSON templates to automate.
o	Resolve policy conflicts (Settings catalog vs baselines) before broad rollout.
6.	Defender for Office 365 validation (if enabled):
o	Confirm preset policies are assigned to the intended pilot users and quarantine processes are defined.
o	Validate Safe Links/Safe Attachments user experience with benign test content (no malware samples).
7.	Purview validation and tuning (if enabled):
o	Confirm labels appear in Office apps for pilot users and guidance/tooltip text makes sense.
o	Run DLP in Audit/Test mode; review alerts and false positives; refine sensitive info types, thresholds, and scope.
o	Only move DLP to enforcement after acceptance criteria are met and comms/training has been delivered.
8.	Copilot readiness checks:
o	Confirm Copilot pilot users are licensed and can access Copilot features.
o	Run the permission boundary tests described in Section 5.2.2 and record outcomes in Appendix B.2.
9.	Update documentation and handover:
o	Update Appendix A (Handover checklist) and attach Evidence outputs.
o	Record all changes (scope, impact, rollback) in Appendix B.1.
o	Schedule the customer IT handover walkthrough and confirm the operating model (Module 6).
