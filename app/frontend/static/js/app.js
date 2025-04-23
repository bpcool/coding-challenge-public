const backendUrl = '__BACKEND_URL__';
const msalConfig = {
    auth: {
        clientId: '850f61bf-a2da-4b73-9789-48a439750d93',
        authority: 'https://login.microsoftonline.com/4c9d30b9-be34-4e1e-9a99-115a85f21d38',
        redirectUri: window.location.origin
    }
};

const msalInstance = new msal.PublicClientApplication(msalConfig);

async function signIn() {
    const loginRequest = {
        scopes: ['User.Read']
    };
    try {
        const loginResponse = await msalInstance.loginRedirect(loginRequest);
        sessionStorage.setItem('msalToken', loginResponse.accessToken);
        fetchPatients(); // load data only after auth
    } catch (error) {
        console.error('Login failed:', error);
        // msalInstance.loginRedirect(loginRequest);
    }
}

window.onload = signIn;

async function fetchPatients() {
    const response = await fetch(`${backendUrl}/patients`);
    const patients = await response.json();
    const patientList = document.getElementById('patientList');
    patientList.innerHTML = '';
    patients.forEach(patient => {
        const row = document.createElement('tr');

        const fullNameCell = document.createElement('td');
        fullNameCell.textContent = patient.full_name;
        row.appendChild(fullNameCell);

        const departmentCell = document.createElement('td');
        departmentCell.textContent = patient.department;
        row.appendChild(departmentCell);

        const bedNumberCell = document.createElement('td');
        bedNumberCell.textContent = patient.bed_number;
        row.appendChild(bedNumberCell);

        const actionsCell = document.createElement('td');
        const deleteButton = document.createElement('button');
        deleteButton.textContent = 'Delete';
        deleteButton.className = 'delete-button';
        deleteButton.onclick = () => deletePatient(patient.id);
        actionsCell.appendChild(deleteButton);
        row.appendChild(actionsCell);

        patientList.appendChild(row);
    });
}

async function addPatient() {
    const fullName = document.getElementById('fullName').value;
    const department = document.getElementById('department').value;
    const bedNumber = parseInt(document.getElementById('bedNumber').value, 10);

    const response = await fetch(`${backendUrl}/patients`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ full_name: fullName, department: department, bed_number: bedNumber })
    });
    if (response.ok) {
        fetchPatients();
        document.getElementById('fullName').value = '';
        document.getElementById('department').value = '';
        document.getElementById('bedNumber').value = '';
    }
}

async function deletePatient(patientId) {
    const response = await fetch(`${backendUrl}/patients?id=${patientId}`, {
        method: 'DELETE'
    });
    if (response.ok) {
        fetchPatients();
    }
}

// document.addEventListener('DOMContentLoaded', fetchPatients);