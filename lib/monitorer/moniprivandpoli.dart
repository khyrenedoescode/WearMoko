import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Monipriandpoli extends StatefulWidget {
  const Monipriandpoli({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MonipriandpoliState createState() => _MonipriandpoliState();
}

class _MonipriandpoliState extends State<Monipriandpoli> {
  // Policy content map containing all the privacy and security topics
  final Map<String, String> _policyContents = {
    'Data Security': """
        We treat your location and status data with the highest level of security because we know how personal and vital it is.

* Encryption In Transit and At Rest: 
        All data transmitted between your device and our servers is secured using TLS/SSL encryption. 
        All sensitive user data, including location history and emergency contact information, is stored on our servers in an encrypted format.
* Data Minimization: 
        We only collect and retain the data absolutely necessary to provide the real-time monitoring and emergency response services you rely on.
* Secure Infrastructure: 
        Our systems are hosted on industry-leading, certified cloud infrastructure with robust physical and digital security protocols.
* Access Control: 
        Access to raw user data is strictly limited to a small number of authorized engineers for specific, necessary maintenance, troubleshooting, and compliance purposes.
""",
    'Digital Safety': """
        Your safety extends beyond the physical—it includes your digital security and safe use of our platform.

* Protecting Your Account: 
        We strongly recommend using a strong, unique password and enabling two-factor authentication (2FA) if offered. Never share your login credentials.
* Safe Usage of Monitoring Features: 
        This application is designed solely for voluntary, consensual real-time monitoring. Misuse of monitoring features (e.g., unauthorized surveillance) will result in immediate account termination.
* Emergency Data Accuracy: 
        For the emergency assistance feature to function correctly, you must ensure that all critical information (emergency contacts) is accurate and kept up-to-date.
* Recognizing Scams: 
        We will never ask you for your password or full credit card details via email or unsolicited messages.
""",
    'Security Measures': """
        We maintain rigorous technical and organizational security measures to protect your data from accidental or unlawful destruction, loss, alteration, unauthorized disclosure, or access.
* Robust Authentication: 
        We use secure, token-based authentication to verify your identity upon login. Sessions are monitored and may be automatically logged out after extended periods of inactivity.
* Regular Audits: 
        Our security framework is regularly audited by third-party experts, and we conduct periodic penetration testing to identify and remediate potential vulnerabilities.
* Incident Response Plan: 
        We maintain a detailed security incident response plan to ensure rapid detection, containment, and recovery in the unlikely event of a security breach.
* Data Retention: 
        We retain your data only for as long as your account is active or as necessary to provide the services and fulfill legal, accounting, or reporting requirements.
""",
    'Control and Transparency': """
        We believe you should have complete control over your data and full transparency regarding its use.
* Explicit Consent for Monitoring: 
        Your real-time location data is only collected and monitored with your explicit, revocable consent. You can disable or pause real-time monitoring at any time within the application settings.
* Disclosure During Emergency: 
        If you activate the emergency feature, your current location, profile details, and emergency contact list will be immediately and automatically shared with our emergency response partners (such as dispatch centers) to facilitate rapid assistance.
* Access to Data Logs: 
        You can view a history of your emergency activations.
* Policy Notification: 
        We will notify you of any material changes to this policy via email or prominent in-app notification.
""",
    'Do Not Sell or Share My Personal Information': """
        We are an emergency assistance service, not a data broker. We do not sell your Personal Information.

* No Sale:
        We do not exchange your name, address, contact information, location history, or any other personal identifiers for monetary compensation.
* Sharing for Service Provision (Not Sale): 
        Any "sharing" of data is strictly limited to what is necessary for the application to function, such as connecting with emergency services or with trusted third-party cloud hosting and payment processing providers.
* Marketing Opt-Out: 
        You have the right to opt-out of receiving any promotional or marketing communications from us at any time.
""",
    'Additional Data Rights': """
        Depending on your jurisdiction, you may have have the following rights concerning your Personal Information.

* Right to Access: 
        You have the right to request a copy of the Personal Information we hold about you.
* Right to Correction: 
        You have the right to request that we correct any Personal Information about you that you believe is inaccurate or incomplete.
* Right to Deletion: 
        You have the right to request the permanent deletion of your account and all associated Personal Information, subject only to legal exceptions.
* Right to Restrict or Object to Processing: 
        You have the right to restrict or object to certain processing activities.
""",
    'Privacy Policy': """
        This is an introduction and summary of the complete legal document.

* Introduction:   
        This Privacy Policy explains how WearMoko collects, uses, shares, and protects your Personal Information in connection with our real-time monitoring and emergency assistance application.
* Data We Collect: 
        We collect Account Data, Real-Time Location Data, Emergency Data (contacts), and Usage Data.
* Contact Information: 
        For any questions or concerns regarding this policy or your data rights, please contact our Data Protection Officer at: alexandergrant.rebusora@hcdc.edu.ph.
* Legal Basis: 
        We process your data based on legal grounds such as necessity to fulfill our contract 0945-588-7410 and your explicit consent.
""",
  };

  // Helper function to build the content with proper bullet points, justification, and formatting
  Widget _buildPolicyContentWidget(String content) {
    final parts = content.split('\n* ');
    final introText = parts.first.trim();
    final bulletItems = parts.sublist(1).map((s) => s.trim()).toList();

    const double boldFontSize = 15.5;
    const double normalFontSize = 14.5;

    final boldTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: boldFontSize,
      color: Colors.black,
    );

    final normalTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w400,
      fontSize: normalFontSize,
      height: 1.5,
      color: Colors.black87,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Introductory Paragraph
        if (introText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Text(
              introText,
              style: normalTextStyle.copyWith(fontSize: boldFontSize),
              textAlign: TextAlign.justify,
            ),
          ),

        // 2. Bulleted List Items
        ...bulletItems.map((item) {
          final parts = item.split(': ');
          final title = parts.first;
          final description =
              parts.length > 1 ? parts.sublist(1).join(': ') : '';

          return Padding(
            // Removed left: 10 from here, relying on dialog content padding
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Bullet point character (Fixed)
                Text(
                  '•  ',
                  style: boldTextStyle.copyWith(
                    fontSize: boldFontSize,
                    color: const Color(0xFFF4B315),
                    height: 1.5,
                  ),
                ),

                // Add a small spacer between bullet and title/content start
                const SizedBox(width: 4),

                // 2. Content Block (Expanded)
                Expanded(
                  // Use a Column to force the description onto a new line
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bold Title Text (First level, aligned near the bullet)
                      Text(
                        description.isNotEmpty ? '$title:' : title,
                        style: boldTextStyle,
                        textAlign: TextAlign.justify,
                      ),

                      // Smaller, Non-bold Description Text (Second level, visibly indented)
                      if (description.isNotEmpty)
                        Padding(
                          // Explicitly increased indentation for the description text
                          padding: const EdgeInsets.only(top: 2.0, left: 15.0),
                          child: Text(
                            description,
                            style: normalTextStyle,
                            textAlign: TextAlign.justify,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Function to show the content in a dialog
  void _showPolicyContent(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Calculate 75% of the screen height for balanced appearance
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight = screenHeight * 0.75;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),

          // Fixed Header (Title)
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: const Color(0xFFF4B315),
            ),
          ),

          // Scrollable Content Body with Max Height Constraint
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: _buildPolicyContentWidget(content),
            ),
          ),

          // Fixed Footer (Actions)
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: _buildPolicyItems(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF4B315),
      elevation: 1,
      centerTitle: true,
      title: Text(
        'Privacy and Policy',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: Colors.black,
        ),
      ),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset('assets/back.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  List<Widget> _buildPolicyItems() {
    return _policyContents.entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () => _showPolicyContent(entry.key, entry.value),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}
