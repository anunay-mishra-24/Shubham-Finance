import { LightningElement, api, track } from 'lwc';
export default class ShfEmploymentVerificationDisplay extends LightningElement {
    @api response; // JSON passed from parent / Apex
    @track sections = [];
    @track failureSections = [];

    connectedCallback() {
        this.response = this.getResponse();
        console.log('Tet', this.response);
        if (this.response?.result) {
            console.log('TESTST ', this.response);
            this.prepareSections(this.response.result);
        }
    }

    prepareSections(result) {
        const sections = [];
        const failures = [];

        /* ========= PERSONAL INFORMATION (2 COLUMN) ========= */
        if (result.personalInfo) {
            sections.push({
                title: 'Personal Information',
                isTwoColumn: true,
                isTable: false,
                fields: this.toTwoColumnFields(result.personalInfo)
            });
        }

        /* ========= EPF HISTORY ========= */
        if (result.nameLookup?.epfHistory?.length) {
            sections.push(
                this.buildTableSection(
                    'EPF History',
                    [
                        { label: 'Wage Month', field: 'wageMonth' },
                        { label: 'Formatted Wage Month', field: 'formatted_wage_month' },
                        { label: 'Total Members', field: 'totalMembers' },
                        { label: 'Total Amount', field: 'totalAmount' }
                    ],
                    result.nameLookup.epfHistory
                )
            );
        }

        /* ========= UAN EMPLOYER DETAILS ========= */
        result.uan?.forEach(uanRec => {
            if (uanRec.employer?.length) {
                sections.push(
                    this.buildTableSection(
                        `UAN Employer Details (${uanRec.uan})`,
                        [
                            { label: 'Employer Name', field: 'name' },
                            { label: 'Member ID', field: 'memberId' },
                            { label: 'Date Of Joining', field: 'dateOfJoining' },
                            { label: 'Date Of Exit', field: 'dateOfExit' },
                            { label: 'Last Month Year', field: 'lastMonthYear' },
                            { label: 'Is Employed', field: 'isEmployed' }
                        ],
                        uanRec.employer
                    )
                );
            }

            if (uanRec.failures?.length) {
                failures.push(...uanRec.failures);
            }
        });

        /* ========= SUMMARY (2 COLUMN) ========= */
        if (result.summary) {
            sections.push({
                title: 'Summary',
                isTwoColumn: true,
                isTable: false,
                fields: this.toTwoColumnFields({
                    'Name Unique': result.summary.nameLookup?.isUnique,
                    'Is Latest': result.summary.nameLookup?.isLatest,
                    'Current Employer': result.summary.uanLookup?.currentEmployer,
                    'Waive FI': result.summary.waiveFi
                })
            });
        }

        /* ========= FAILURES (LAST) ========= */
        if (result.failures?.length) {
            failures.push(...result.failures);
        }

        this.sections = sections;
        this.failures = (failures.length) ? failures : undefined;
    }

    /* ================= UTILITIES ================= */

    buildTableSection(title, columns, rawRows) {
        return {
            title,
            isTwoColumn: false,
            isTable: true,
            columns,
            rows: rawRows.map((row, index) => ({
                id: index,
                cells: columns.map(col => ({
                    key: col.field,
                    value: row[col.field] ?? 'NA'
                }))
            }))
        };
    }

    toTwoColumnFields(obj) {
        return Object.keys(obj).map(key => ({
            label: this.formatLabel(key),
            value: obj[key] ?? 'NA'
        }));
    }

    formatLabel(key) {
        return key
            .replace(/([A-Z])/g, ' $1')
            .replace(/^./, c => c.toUpperCase());
    }

    getResponse(){
        let response = JSON.parse(`{
            "result": {
                "email": {},
                "nameLookup": {
                "organizationName": "TECHMATRIX IT CONSULTING PRIVATE LIMITED",
                "epfHistory": [
                    {
                    "totalAmount": 0,
                    "totalMembers": "NA",
                    "formatted_wage_month": "2511",
                    "wageMonth": "NOV-25"
                    },
                    {
                    "totalAmount": 0,
                    "totalMembers": "NA",
                    "formatted_wage_month": "2510",
                    "wageMonth": "OCT-25"
                    },
                    {
                    "totalAmount": 0,
                    "totalMembers": "NA",
                    "formatted_wage_month": "2509",
                    "wageMonth": "SEP-25"
                    }
                ],
                "estInfo": [],
                "matches": [],
                "isNameExact": false,
                "isEmployed": false,
                "isRecent": false,
                "isNameUnique": false,
                "employeeName": "NIMISHA GOYAL"
                },
                "uan": [
                {
                    "uan": "101336546292",
                    "uanSource": "pan",
                    "employer": [
                    {
                        "name": "TECHMATRIX IT CONSULTING PRIVATE LIMITED",
                        "memberId": "MRNOI15541170000010332",
                        "settled": null,
                        "dateOfExit": null,
                        "dateOfJoining": "2022-08-09",
                        "lastMonthYear": "",
                        "startMonthYear": "08-2022",
                        "employmentPeriod": null,
                        "isNameUnique": false,
                        "matchName": "NIMISHA GOYAL",
                        "lastMonth": "",
                        "isRecent": false,
                        "isNameExact": false,
                        "isEmployed": true,
                        "nameConfidence": null,
                        "emplrScore": null,
                        "uanNameMatch": null
                    }
                    ],
                    "failures": []
                }
                ],
                "personalInfo": {
                "uan": "101336546292",
                "name": "NIMISHA GOYAL",
                "dateOfBirth": "1997-04-04",
                "gender": "F",
                "fatherHusbandName": "SATISH CHAND GOYAL",
                "relation": "F",
                "nationality": null,
                "maritalStatus": null,
                "qualification": null,
                "mobileNumber": "8171600151",
                "emailId": "nimisha97goyal@gmail.com",
                "pan": "CMRPG1632H",
                "passport": null
                },
                "summary": {
                "nameLookup": {
                    "isUnique": false,
                    "isLatest": false,
                    "result": false
                },
                "uanLookup": {
                    "currentEmployer": "TECHMATRIX IT CONSULTING PRIVATE LIMITED",
                    "matchScore": null,
                    "result": null,
                    "uanNameMatch": null
                },
                "waiveFi": false
                },
                "failures": [],
                "pdfLink": "https://download.karza.in/file/IS7mugnzwiXaf275L9HeHLk7kwTEhYR-OZrS0CpFG_RpD-zN8QplP1Y509E9AJ-3AiCb-Vd7ckQZgRyUI7yqkBmjKGF9K8bIv09vk1ShDfOGnzVP2dog3x2j4Y1-NhCKhPGJ29uUaJ56fU6B2-UMwxTCp6U3f2PfNNX5YrRKWOnp1zACF8BBeOGdn38T5R8G3czEO75N0RWIGVAM1vhUMU6i6vL8g9zOahoERzqK3Iksp6j1FzTmKysDIcKHXMF096Qk4Z5akTXLJuY9jOsTkUpLH5RWgZrB1tTDU1UE5ZWqQp6HuePaOrzZVzxplhvARqtTyztW3dg1RQ7zCt9daiLkGAla_r5RtAVGEp3IvJo%3D%24vRoGJs2YubrQ4W8xKG2Unqq9mJCx1mgsd4wbqeqF4vp/6HkMUPjsbKRsStWP3y39eOc6SIl386_qaqzOThUYgZg"
            },
            "request_id": "4f85dcbb-7066-47a9-a98e-eb782e419a14",
            "status-code": "101"
        }`);
        return response;
    }
}