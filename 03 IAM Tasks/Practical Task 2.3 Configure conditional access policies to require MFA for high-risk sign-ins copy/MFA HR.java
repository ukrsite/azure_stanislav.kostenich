To configure Conditional Access policies in Azure Active Directory to require Multi-Factor Authentication (MFA) for high-risk sign-ins, follow these steps:

---

### **Step 1: Prerequisites**
Ensure the following prerequisites are met:  
1. **Azure AD Premium P2 License**: Required to access Identity Protection and risk-based policies.  
2. **Global Administrator or Security Administrator Role**: Necessary permissions to configure policies.  
3. **Identity Protection Enabled**: High-risk sign-ins are detected by Azure AD Identity Protection.

---

### **Step 2: Access the Conditional Access Page**
1. Sign in to the [Azure Portal](https://portal.azure.com).  
2. Navigate to **Azure Active Directory** → **Security** → **Conditional Access**.

---

### **Step 3: Create a New Policy**
1. **Click on "+ New policy"** and provide a name for your policy (e.g., "Require MFA for High-Risk Sign-Ins").  

---

### **Step 4: Configure Assignments**
1. **Users or workload identities**:  
   - Select **All users** to apply the policy broadly, or choose specific groups.  
   - Exclude break-glass or emergency access accounts to prevent accidental lockouts.  

2. **Cloud apps or actions**:  
   - Select **All cloud apps** to ensure broad protection or target specific apps.  

3. **Conditions**:  
   - **Sign-in risk**:  
     - Click **Conditions** → **Sign-in risk** → **Configure**.  
     - Select **High** (you may also include **Medium** if desired).  

---

### **Step 5: Configure Access Controls**
1. Under **Access controls**, select **Grant**.  
2. Choose **Require multi-factor authentication**.  
3. (Optional) Combine with other access requirements, such as requiring a compliant device.  

---

### **Step 6: Enable and Test the Policy**
1. **Set the policy state** to **On** and click **Create**.  
2. Test the policy by simulating a high-risk sign-in or reviewing its impact in **Report-only** mode 
before enforcing.  

---

### **Step 7: Monitor and Fine-Tune**
1. Use the **Sign-in logs** under **Azure AD → Monitoring** to verify the policy’s effectiveness.  
2. Adjust the policy based on user feedback or specific requirements.  

---

### **Example Use Case**
For a user with a detected high-risk sign-in, the policy will enforce MFA during login. 
If the user cannot satisfy MFA requirements, access will be denied.

Would you like a step-by-step guide for any specific part or additional configurations?