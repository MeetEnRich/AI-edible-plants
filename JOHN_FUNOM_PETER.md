AN AI POWERED APP FOR IDENTIFYING AND CATALOUGING LOCAL EDIBLE PLANTS









# BY

PETER, John Funom

# (2021/CP/CSC/0038)









A PROJECT REPORT SUBMITTED TO THE DEPARTMENT OF COMPUTER SCIENCE, FACULTY OF COMPUTING, IN PARTIAL FULFILLMENT OF THE REQUIREMENTS FOR THE AWARD OF BACHELOR OF SCIENCE (BSc) DEGREE IN COMPUTER SCIENCE. OF FEDERAL UNIVERSITY OF LAFIA.











# MARCH, 2026



# CHAPTER ONE

# INTRODUCTION

## 1.1 Background of Studies

​The vast and rich botanical landscape of Nigeria represents a significant portion of West Africa’s biodiversity, serving as a primary repository for indigenous food sources and medicinal flora. For decades, the identification and classification of these plants have been deeply rooted in the ethno-botanical traditions of local communities, where knowledge regarding the edibility, nutritional value, and preparation of wild flora is passed down through oral history (Kalaivani et al., 2025; Long et al., 2023). However, this traditional knowledge system is currently under severe pressure due to rapid urbanization, habitat loss, and the progressive aging of traditional practitioners, leading to what many researchers call a "generational knowledge gap" (Nwala et al., 2023; Tadesse et al., 2024).

​From a scientific perspective, the task of plant identification assigning a specific specimen to a known taxon based on morphological characters is traditionally the domain of professional botanists using dichotomous keys and physical herbaria (Arora, 2025; Martins, 2025). This manual process involves analyzing qualitative traits like leaf arrangement and ovary position, alongside quantitative features like petal counts and flower width (Singh et al., 2021). While effective, these methods are time-intensive and require specialized expertise that the general public often lacks.

​The emergence of Artificial Intelligence (AI) and Computer Vision (CV) has introduced a transformative approach to this botanical challenge. Early automated identification systems primarily relied on Support Vector Machines (SVMs) and K-Nearest Neighbors (kNN) to process hand-crafted feature vectors derived from leaf textures and shapes (Kadir et al., 2020; Singh et al., 2021). Recent advancements have shifted the focus toward Deep Learning architectures, specifically Convolutional Neural Networks (CNNs) and Vision Transformers (ViTs), which simulate human visual reasoning to detect fine-grained patterns with high precision (Alhwaiti et al., 2025; Du et al., 2024). Today, the integration of Multimodal Large Language Models (MM-LLMs) accessible through third-party Application Programming Interfaces (APIs) allows for the creation of high-performance mobile applications that can reason about images and text simultaneously without requiring local training of massive datasets (Castillo, 2024; Singh et al., 2026).



## 1.2 Research Motivation

​The drive for this research is rooted in the urgent necessity to bridge the gap between traditional botanical wisdom and modern digital technology. One of the most significant barriers to foraging and the sustainable use of local plants is the "identification hurdle" the initial difficulty of knowing exactly what a plant is (borringman, 2024). An AI-powered starting point can democratize this expertise, allowing non-experts to interact safely with their environment.

​Furthermore, the technological feasibility of this project has been greatly enhanced by the availability of high-end multimodal APIs. These cloud-based services offer expert-level image recognition and reasoning capabilities at a fraction of the cost of developing a custom deep learning model from scratch (Castillo, 2024; Google, 2024). By leveraging these advanced APIs within a mobile framework, this project seeks to provide a localized solution for Nigerians to document, identify, and catalogue their edible plant heritage, ensuring that this vital information is preserved in a structured digital format for future generations.

## 1.3 Statement of the Problem

​The process of identifying edible plants in the wild is currently plagued by high risks and significant technical barriers. For the average person in Nigeria, distinguishing between an edible local vegetable and a toxic look-alike is often a matter of trial and error or reliance on dwindling expert knowledge. Studies have shown that many general-purpose identification apps frequently fail in real-world conditions, sometimes misidentifying toxic species as edible (Long et al., 2023; Public Citizen, 2024). This poses a severe public health risk.

​Furthermore, most existing plant identification tools are optimized for Western or temperate flora, often lacking the localized taxonomic data required for West African species. There is a notable absence of a centralized mobile platform that not only identifies these plants but also "catalogues" them with relevant cultural data such as vernacular names, traditional preparation methods, and seasonal availability (Ariwaodo et al., 2020; Meregini, 2023). Without a reliable, localized system that integrates image recognition with a structured cataloguing database, the potential of indigenous edible plants to contribute to national food security remains vastly underutilized.







## 1.4 Aim and Objectives

​The primary aim of this project is to design and implement an AI-powered mobile application for the identification and systematic cataloguing of local edible plants in Nigeria using high-end multimodal APIs.

The specific objectives are as follows:

To design and develop a user-friendly mobile application interface capable of capturing and processing high-resolution botanical images.

To integrate a third-party Multimodal AI API to perform real-time species recognition and generate detailed plant descriptions.

To implement a secure cataloguing system that allows users to store and organize their identifications with associated metadata.

To develop a safety-first recommendation module that uses Explainable AI (XAI) to provide users with clear edibility warnings and traditional preparation protocols.

## 1.5 Significance of the Study

​The significance of this study is extensive and multi-faceted, touching on economic, educational, and socio-cultural dimensions:

Agricultural and Food Security: By providing an accessible tool for identifying wild edible plants (WEPs), the project supports the diversification of the Nigerian diet. This is particularly crucial during food shortages, as underutilized indigenous crops can serve as essential nutritional buffers (Tadesse et al., 2024; Umar et al., 2025).

Educational and Scientific Research: The application acts as a portable "digital botanist," assisting students, researchers, and hobbyists in learning about plant taxonomy and ecology in the field. This reduces the "cost of expertise" and encourages interest in the biological sciences (Arora, 2025; Singh et al., 2023).

Socio-Cultural Preservation: Digitizing traditional knowledge regarding local plants ensures that this heritage is not lost with the passing of the elderly generation. It allows for the documentation of local vernacular names and cultural uses in a format that appeals to the tech-savvy youth (Ezekwe et al., 2026; Nwala et al., 2023).

Economic Empowerment: The app can facilitate the sustainable harvesting of economic plants, potentially connecting local foragers with markets and ensuring that valuable resources are recognized and protected (Ariwaodo et al., 2020).

Technical Contribution: This study provides a blueprint for developing high-utility AI applications in resource-constrained environments. It demonstrates how Nigerian developers can leverage cloud-based APIs to build sophisticated systems without the need for prohibitive hardware investments.

## 1.6 Scope of the Study

​The scope of this research covers the full development lifecycle of a mobile application from conceptual design to implementation and testing.

Functional Scope: The app will focus on three core functionalities: real-time identification via image capture, structured cataloguing of identified specimens, and edibility/safety advisory.

Botanical Scope: The system is specifically targeted at "edible" flora found within the Nigerian ecological zones, including wild fruits, leafy vegetables, and seeds used as soup condiments.

Technical Scope: The project involves the use of cross-platform mobile development frameworks, secure backend API integration, and cloud-based database management. It will utilize third-party multimodal AI services for the heavy computational task of image analysis.

Geographical Scope: While designed for use across Nigeria, the initial validation and reference data will be centered on common species found in Southern Nigerian rainforest and savanna ecotones.

## 1.7 Limitation of the Study

​The implementation and reliability of the system are subject to the following constraints:

Internet Connectivity: As the application relies on cloud-based APIs for identification, its performance is highly dependent on a stable internet connection, which may be limited in remote rural areas (Kalaivani et al., 2025).

API Rate Limits and Costs: The project is bound by the usage quotas and potential subscription costs of the third-party AI service provider, which may affect large-scale deployment.

Environmental Variations: Identification accuracy can be affected by poor lighting conditions, image blurring, or physical occlusions where a specimen is partially hidden by other vegetation (Alhwaiti et al., 2025; Singh et al., 2021).

Taxonomic Database Gaps: Some rare or highly localized Nigerian plant species may not be fully represented in the global training data of the AI model, potentially leading to lower confidence scores (Long et al., 2023).

Hardware Limitations: The quality of identification is partly dependent on the resolution and focal capabilities of the user's smartphone camera.

Safety Disclaimer: While the AI provides high-precision guesses, it cannot replace professional lab testing; users must be warned that the app is an educational aid and not a definitive safety guarantee for consumption (Public Citizen, 2024).

## 1.8 Definition of Operational Terms

Artificial Intelligence (AI): A branch of computer science that develops systems capable of performing tasks typically requiring human intelligence, such as visual perception and decision-making.

Multimodal Large Language Model (MM-LLM): An advanced AI model that can process and reason across multiple types of data, such as images and text, in a single integrated framework.

Application Programming Interface (API): A set of rules and protocols that allows the mobile application to communicate with a remote server or AI service to perform specific tasks.

Computer Vision (CV): A field of AI that enables computers to derive meaningful information from digital images or videos.

Cataloguing: The systematic process of recording, organizing, and storing data about identified plant specimens in a searchable database.

JSON (JavaScript Object Notation): A lightweight data-interchange format used by the app to receive structured information from the AI API.

Explainable AI (XAI): A set of tools and frameworks that help explain why an AI model reached a specific conclusion, which is used here to describe the visual traits of a plant.

Ethnobotany: The study of the relationship between people and plants, focusing on traditional knowledge and cultural usage.

Taxonomy: The scientific discipline of naming, defining, and classifying groups of biological organisms based on shared characteristics.

Cross-Platform Development: The practice of building a mobile application that can run on both Android and iOS operating systems using a single codebase.



# CHAPTER TWO

# LITERATURE REVIEW

## 2.1 Conceptual Framework

​The conceptual framework of this study represents a multi-disciplinary intersection where traditional botany, computer vision, and cloud-based generative artificial intelligence converge. This framework is designed to provide a theoretical roadmap for the transition from manual, expertise-heavy plant identification to an automated, democratic system accessible via mobile technology.

## 2.1.1 Digital Ethnobotany and Taxonomic Foundations

​At its core, the study is grounded in the principles of Linnaean taxonomy the science of naming and classifying organisms based on shared physical characteristics (Martins, 2025). Historically, identifying edible flora required an analysis of morphological traits such as leaf arrangement, flower structure, and seed type (Arora, 2025). However, the framework of "Digital Ethnobotany" posits that this botanical expertise can be codified and preserved using digital tools to bridge the generational knowledge gap (Tadesse et al., 2024). This project adopts the view that digital cataloging is not merely a technical task but a cultural preservation effort, ensuring that indigenous names and traditional preparation methods are stored in a persistent, machine-readable format (Soni, 2025).

## 2.1.2 Evolution of Botanical Computer Vision

​The technical pillar of this framework traces the evolution of Image Recognition. In the early 2010s, automated identification was restricted to "Feature Engineering," where developers manually programmed the system to recognize specific edge histograms or color profiles using algorithms like Support Vector Machines (SVM) (Singh et al., 2021). The conceptual shift toward "Deep Learning" (DL) allowed systems to learn these features automatically through hierarchical layers of Convolutional Neural Networks (CNNs) (Alhwaiti et al., 2025). This project utilizes the modern iteration of this evolution: Vision-Language Models (VLMs). Unlike standard CNNs that only output a class label, VLMs reason across visual and textual domains simultaneously, allowing the system to not just identify a plant but to understand its ecological context and safety profile (Castillo, 2024; Google, 2024).

## 2.1.3 API-Centric Architecture and In-Context Learning

​A significant conceptual departure in this research is the move away from model training toward "In-Context Learning" (ICL) facilitated by third-party APIs. Traditional AI projects require local hardware to update model weights, a process that is computationally prohibitive for most students (Singh et al., 2026). The API-centric framework treats the AI as a black-box service that is "prompted" rather than "trained." By providing a multimodal model with a few high-quality reference images and textual instructions (Few-Shot Prompting), the system can achieve professional-grade accuracy in identifying Nigerian-specific species without needing a massive local dataset (Kindwise, 2025; Castillo, 2024).

## 2.1.4 The Safety and Explainability (XAI) Framework

​Given the high-risk nature of identifying edible plants, the framework incorporates "Explainable AI" (XAI). Most identification apps operate as "black boxes" that give a result without justification (Long et al., 2023). This project frames the identification process as a dialogue where the AI must justify its conclusion based on visual evidence (e.g., "identified as Vernonia due to the serrated leaf margin and characteristic purple inflorescence"). This approach prioritizes user safety and serves as a pedagogical tool to improve the user's own botanical skills over time (Public Citizen, 2024).

## 2.2 Related Works

## 2.2.1 Mobile App for Medicinal Plant Identification and Authenticity

​Kalaivani et al. (2025) explored the development of a mobile application using React Native and Firebase, integrated with the Perenual Plant Identification API. Their study achieved an 86% accuracy rate in real-world identification of medicinal species. The work is particularly notable for integrating a "Verified Seller" badge and geolocation features, which link identified plants to local marketplaces. This study provides a foundational blueprint for how API-driven apps can bridge the gap between identification and the broader agricultural supply chain (Kalaivani et al., 2025).

## 2.2.2 Performance Analysis of YOLO Models for Plant Detection

​Alhwaiti et al. (2025) conducted a rigorous comparison between YOLOv3 and YOLOv4 architectures for the real-time detection of plant pathologies. Their findings indicated that YOLOv4 achieved a 98% Mean Average Precision (mAP) with a significantly reduced detection time of 29 seconds. While the study focused on diseases, its emphasis on low-latency processing and "fine-grained visual patterns" underscores the technical requirements for mobile identification tools designed for field use in varied lighting conditions (Alhwaiti et al., 2025).





## 2.2.3 Reliability Risks in Foraging Applications

​A critical study by (Long et al., 2023) evaluated the accuracy of popular apps like PictureThis and PlantSnap. The researchers discovered that while apps were proficient at genus-level identification (76%), they frequently failed at the species level, with five out of eleven toxic species being misidentified as edible. This literature serves as a vital warning for current developers, highlighting the need for rigorous safety filters and human-in-the-loop verification processes in any app targeting foraged foods (Long et al., 2023; Public Citizen, 2024).

## 2.2.4 In-Context Learning for Botanical Image Classification

​(Castillo, 2024) demonstrated the technical feasibility of using the Gemini 1.5 Flash API for multimodal tasks. By utilizing "Few-Shot Learning" providing five example images per class within the API prompt identification accuracy rose from 73% to 90%. This work is central to the current project’s methodology, as it proves that high-end multimodal APIs can generalize to specific plant species without the need for traditional model fine-tuning or specialized hardware (Castillo, 2024).

## 2.2.5 Indigenous Edible Wild Fruits in the Niger Delta

​(Nwala et al., 2023) documented 36 indigenous wild fruit species regularly consumed in Rivers State, Nigeria. Their ethnobotanical survey highlighted that many of these species, though rich in nutrients, are underutilized due to a lack of formal documentation. This research justifies the "cataloging" objective of the current project, as it demonstrates that identifying a plant is only the first step toward revitalizing indigenous food systems (Nwala et al., 2023).

## 2.2.6 Comparative Accuracy: Specialized vs. General Purpose APIs

​A benchmark study by (Kindwise, 2025) compared the specialized Plant.id API with the general-purpose GPT-4V model. The results showed that specialized models had a much lower misidentification rate (12%) than general models (58%) for top-1 species suggestions. This research informs the project's strategy to use rigorous prompt engineering and regional constraints to "tame" general multimodal APIs for specialized botanical identification (Kindwise, 2025).

## 2.2.7 Mobile-enabled Plant Diagnosis-Application (mPD-App)

​(Asani et al., 2023) developed a web-based plant diagnosis tool specifically for Sub-Saharan Africa. Utilizing a CNN architecture, the system achieved a 93.9% accuracy rate across 14 different plant diseases. Their work highlights the importance of "product-oriented, user-friendly" designs that empower local farmers. The study provides a regional precedent for the deployment of mobile AI tools to address food security challenges in Nigeria (Asani et al., 2023).

## 2.2.8 Hybrid DenseNet for fine-grained Pathology Detection

​(Singh et al., 2026) introduced a hybrid DenseNet model incorporating Squeeze-and-Excitation (SE) blocks and hyperparameter optimization via KerasTuner. The model achieved accuracy values close to 99% for rice leaf diseases. This study emphasizes that "joint feature refinement" is necessary to distinguish between visually similar botanical specimens, suggesting that AI prompts should specifically direct the model to analyze leaf venation and textures (Singh et al., 2026).

## 2.2.9 Ethnobotanical Survey of WEPs in Northwestern Ethiopia

​(Tadesse et al., 2024) investigated 51 species of Wild Edible Plants (WEPs), noting that they serve as a "vital nutritional buffer" during lean seasons. The study employed semi-structured interviews and field walks to document traditional knowledge. The findings underscore the urgency of digitizing such knowledge as habitats are lost to agricultural expansion, providing the socio-economic rationale for an identification and cataloging app (Tadesse et al., 2024).

## 2.2.10 AI in Medicinal Plant Research and Health Assessment

​(Gupta et al., 2024) reviewed how machine learning algorithms can automate the measurement of plant phenotypes and real-time monitoring of growth. Their work discusses the integration of AI-driven sensing techniques to optimize plant life cycles. This is relevant for a cataloging app that aims to record seasonal data and growth patterns of local flora in a structured database (Gupta et al., 2024; Ahmad et al., 2023).

## 2.2.11 AgEval: Benchmarking VLMs for Agricultural Tasks

​(Arshad et al., 2024) developed the AgEval framework to evaluate the "few-shot" adaptability of Vision-Language Models (VLMs) like Gemini and Claude. They found that exact category examples in a prompt improved F1 scores by an average of 15.38%. This literature provides a scientific basis for using multimodal prompts to enhance the reliability of generic AI APIs for Nigerian agricultural contexts (Arshad et al., 2024).

## 2.2.12 Impact of AI in Sustainable Forest Management in Nigeria

​Federal Ministry of Environment researchers (2022) explored how AI-based image analysis could classify vegetation types and estimate biomass in Nigerian forests. The study advocates for the use of digital tools to monitor forest health and track rare species. This work supports the project’s "Citizen Science" objective, where user-contributed sightings can help map the distribution of edible flora across Nigerian states (Mackey et al., 2021; Gbadebo et al., 2022).

## 2.2.13 Real-time Identification in Tropical Environments

​(Malik et al., 2022) applied deep learning for identifying medicinal plants in Borneo, achieving high accuracy in complex field settings. Their research demonstrated that AI could overcome environmental noise (e.g., cluttered backgrounds) which is common in tropical rainforests. This validates the feasibility of using mobile cameras for species identification in Nigerian savanna and forest transition zones (Malik et al., 2022).

## 2.2.14 User impressions and Network Challenges in ID Apps

​(Bawingan et al., 2024) conducted a survey of users’ impressions of plant ID apps, identifying slow internet connectivity as a primary barrier (64.6% of respondents). This work is crucial for the technical design of the app, as it highlights the need for lightweight web protocols and local caching mechanisms to ensure the app remains functional in rural Nigeria (Bawingan et al., 2024; Jude et al., 2025).

## 2.2.15 Explainable AI (XAI) for Poisonous Plant Prediction

​(Alruwaili et al., 2025) proposed an XAI approach to clarify AI decision-making when predicting plant toxicity. By using explanation techniques to show why a plant was labeled poisonous, they fostered greater user trust and achieved a 94% accuracy rate. This study reinforces the need for the current project to include a reasoning layer in its API calls to minimize the risk of accidental consumption of toxic look-alikes (Alruwaili et al., 2025).

## 2.3 Summary of Literature

## 2.4 Research Gaps of the Study

​Despite the extensive literature reviewed, several critical gaps remain that this project seeks to address:

Lack of Localized Vernacular Integration: Most international plant identification APIs are trained on Western datasets and return only English common names. There is a "data silo" where Nigerian vernacular names (e.g., Igbo, Yoruba, Hausa) are not programmatically linked to AI identification results (Kalaivani et al., 2025; Nwala et al., 2023).

Disconnected Identification and Cataloging Workflow: Existing apps like PlantSnap operate as "fire-and-forget" identification tools. There is a lack of mobile systems that allow a user to build a persistent, geotagged "digital herbarium" of their own findings specifically for the purpose of personal food resource management (Bawingan et al., 2024; Ariwaodo et al., 2020).

Safety and "Look-Alike" Explainability: While apps like PictureThis are highly accurate, they rarely explain the morphological differences between an edible plant and its toxic mimic. This study addresses this gap by implementing an Explainable AI (XAI) layer using multimodal reasoning to point out specific visual traits that confirm edibility (Long et al., 2023; Alruwaili et al., 2025).

Hardware Barrier for Local Developers: Much of the existing academic literature (e.g., Asani et al., 2023; Singh et al., 2026) focuses on training custom models, which requires expensive GPU resources. There is a gap in research documenting the effective deployment of high-utility botanical apps using purely API-driven serverless architectures in the Nigerian university context (Castillo, 2024).

Integration of Traditional Preparation Protocols: Identifying a wild plant as "edible" can be dangerous without knowing the required processing (e.g., boiling Ugba to remove toxins). Current apps lack a module for traditional "preparation protocols" specific to the West African culinary landscape (Tadesse et al., 2024). This study integrates these cultural preparation guides directly into the AI response.



# CHAPTER THREE

# METHODOLOGY AND ANALYSIS OF THE PROPOSED SYSTEM

## 3.1 Methodology

The methodology to be adopted for this project is the Structured System Analysis and Design Methodology (SSADM). This framework is selected because it provides a highly disciplined, data-driven approach to software engineering, which is essential for a system that will handle critical information regarding the edibility of wild flora (Soni, 2025). SSADM focuses on the logical analysis of requirements and the separation of design from the physical implementation, ensuring that the system's architecture will be robust, scalable, and tailored to the unique needs of Nigerian users (Kalaivani et al., 2025).

As a structured approach, SSADM will guide the achievement of the project’s objectives through a series of sequential stages:

## 3.1.1 Feasibility Study

The initial phase will involve a rigorous investigation into whether an AI-powered solution for plant identification is practically and economically viable in a Nigerian context. This study will evaluate the availability of multimodal APIs that can provide expert-level botanical reasoning without the need for expensive on-site server hardware (Castillo, 2024). The analyst will determine if the proposed use of cloud-based reasoning will effectively bridge the "knowledge gap" between traditional botanical expertise and modern digital users (Singh et al., 2026).

## 3.1.2 Requirement Analysis

In this stage, the functional and non-functional requirements of the application will be established. The research will identify the specific needs of local foragers and students, such as the requirement for vernacular names in Igbo, Hausa, or Yoruba, and the necessity for "Explainable AI" (XAI) to describe the visual traits justifying a plant’s edibility (Long et al., 2023; Public Citizen, 2024). This analysis will define exactly what the system will do before any coding begins.

## 3.1.3 Requirement Specification

The gathered requirements will be translated into detailed technical specifications. The system will be designed to support high-resolution image uploads, and a safety-first notification module (Alruwaili et al., 2025). This phase ensures that the final product will align with the project’s core aim of providing a reliable and safe identification tool (Asani et al., 2023).

## 3.1.4 Logical System Specification

This stage will involve mapping out the logical flow of data through the system components. The design will define how an image will travel from the mobile interface to a secure backend gateway and finally to the multimodal API for processing (Singh et al., 2021). The resulting metadata (species name, family, and prep methods) will then be structured into a standard format (like JSON) for storage and display (Kindwise, 2025).

## 3.1.5 Physical Design

The final stage will involve the actual mapping of logical designs to physical development tools. This phase will focus on optimizing the app for the Nigerian environment, ensuring it remains functional under varied network conditions through the use of lightweight web protocols and local caching mechanisms (Bawingan et al., 2024; Jude et al., 2025).

## 3.2 Development Tools Used

To ensure that the application is modern, responsive, and cross-platform, a comprehensive "Full-Stack" set of tools will be utilized:

Mobile Frontend Framework: The app will be developed using a cross-platform framework (such as React Native or Flutter) to ensure it can run seamlessly on both Android and iOS devices, which is critical for maximizing user accessibility across Nigeria (Kalaivani et al., 2025; Malik et al., 2022).

Backend Environment: A server-side environment (like Node.js or FastAPI) will serve as a secure gateway for API calls. This is essential for protecting sensitive API keys and managing user requests efficiently before they are sent to the cloud AI service (Rabibsust, 2024).

Multimodal AI API: The "brain" of the identification system will be a high-end third-party Multimodal API. These models will be utilized to "see" and "reason" over botanical images in real-time, providing scientific and cultural data without the high computational burden of training a local model (Castillo, 2024; Singh et al., 2026).

Database Management System: A cloud-hosted database (such as Firebase Firestore or MongoDB) will be used to implement the cataloguing feature. This will allow the application to persistently store user-specific plant logs, and historical identification data (Kalaivani et al., 2025; Soni, 2025).

Design and Styling: Tailwind CSS and modern UI libraries will be used to create an intuitive user interface that is optimized for outdoor use, ensuring visibility and ease of navigation during field foraging (Rabibsust, 2024).

## 3.3 Database Design

The application’s database will follow a relational logic to ensure data integrity and allow for complex queries within the cataloguing feature. The design will comprise three primary tables that interact to provide a complete "Digital Herbarium" experience.

## 3.3.1 Data Tables and Entities

Users Table: This table will store essential authentication data for the application.

Fields: UserID (PK), Username, Email, PasswordHash, ProfileImage, 	AccountCreated.

PlantCatalog (Identifications) Table: This central table will log every successful plant identification session.

Fields: RecordID (PK), UserID (FK), ScientificName, CommonName, 	LocalName, ConfidenceScore, ImageStorageURL, Latitude, Longitude, 	Timestamp.

IndigenousMetadata Table: This will act as a reference repository for localized cultural knowledge.

Fields: PlantID (PK), ScientificName, Family, IgboName, HausaName, 	YorubaName, PreparationMethods, SafetyWarnings.

## 3.3.2 Database Relationships

The database will implement a One-to-Many (1:M) relationship between the Users table and the PlantCatalog table, meaning one user will be able to store many different plant identifications over time. Additionally, the PlantCatalog table will have a lookup relationship with the IndigenousMetadata table based on the ScientificName returned by the AI, allowing the system to automatically append local names and preparation protocols to each record (Kalaivani et al., 2025; Soni, 2025).

## 3.4 System Design

To represent the system's architecture and behavioral flow, two Unified Modeling Language (UML) diagrams and a system flowchart are provided.







## 3.4.1 Use Case Diagram

The Use Case diagram will illustrate how the primary actors will interact with the system’s boundary.

Actors: The primary actor is the User (forager/student), and the secondary actor is the Multimodal AI API.

Proposed Use Cases:

Image Capture: The user will photograph a plant specimen.

Identify Plant: The system will send the image to the AI for analysis.

View Safety reasoning: The system will provide XAI-based justifications for identification (Alruwaili et al., 2025).

Catalog Identification: The system will save the result and location to the user's history.

Browse Catalogue: The user will review their personal digital herbarium.









## 3.4.2 Sequence Diagram

The Sequence Diagram will model the time-ordered interactions between objects during an identification request.

User will initiate an identification by capturing an image via the Mobile UI.

Mobile UI will send the Base64-encoded image to the Backend Server.

Backend Server will append localized system instructions and forward the request to the Multimodal AI API.

AI API will return a JSON object containing the plant's scientific details and a confidence score.

Backend Server will then query the Database to fetch local names and save the identification log.

Database will confirm the transaction.

Backend Server will return the final enriched data to the Mobile UI for the user to view.







## 3.4.3 System Flowchart

The flowchart will provide the step-by-step logic the application will follow from start to finish.

Start: App initialized.

Step 1: User will be prompted to capture or upload a plant image.

Decision: Is the image quality sufficient (sharp/well-lit)?

No: User will be asked to retake the photo (Long et al., 2023).

Yes: The system will process and encode the image.

Step 2: A request will be made to the AI reasoning engine via the backend.

Step 3: The AI will return species metadata.

Step 4: The system will automatically fetch localized preparation data and safety warnings.

Step 5: Results will be displayed to the user and automatically saved to the persistent catalog.

End: The session will conclude, and the user will be returned to the main dashboard.





# REFERENCES

Alhwaiti, Y., Khan, M., Asim, M., Siddiqi, M. H., Ishaq, M., & Alruwaili, M. (2025). Leveraging YOLO deep learning models to enhance plant disease identification. Research Gate. https://www.researchgate.net/publication/389659671_Leveraging_YOLO_deep_learning_models_to_enhance_plant_disease_identification

Alruwaili, M., et al. (2025). Explainable Deep Inherent Learning for plant species classification and poisonous status prediction. Sensors, 25(14). https://www.mdpi.com/1424-8220/25/14/4298

Ariwaodo, J. O., Obidike-Ugwu, E. O., Ugwu, R. A., & Ezekwe, C. O. (2020). Checklist of tree species of Humid Forest Research Station, Forestry Research Institute of Nigeria (FRIN), Umuahia, Abia State, Nigeria. Journal of Environmental Science and Management, 13(6). https://ejesm.org/wp-content/uploads/2020/12/ejesm.v13i6.5.pdf

Arshad, M. A., Jubery, T. Z., Roy, T., Nassiri, R., Singh, A. K., Singh, A., Hegde, C., Ganapathysubramanian, B., Balu, A., Krishnamurthy, A., & Sarkar, S. (2024). AgEval: Leveraging Vision Language Models for specialized agricultural tasks. arXiv. https://arxiv.org/pdf/2407.19617

Asani, E. O., Osadeyi, Y. Y. P., Adegun, A. A., Viriri, S., Ayoola, J. J. A., & Kolawole, E. E. A. (2023). mPD-APP: A mobile-enabled plant diseases diagnosis application using convolutional neural network toward the attainment of a food secure world. Frontiers in Artificial Intelligence, 6. https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2023.1227950/full

Bawingan, J. S., et al. (2024). Plant identification mobile apps: Users’ difficulties and impressions. Asian Journal of Biology Education, 16.(https://www.researchgate.net/publication/380347896_Plant_Identification_Mobile_Apps_Users'_Difficulties_and_Impressions)

Castillo, D. (2024). Classify images with Gemini Flash 1.5. Dylan Castillo Technical Blog. https://dylancastillo.co/posts/classify-images-with-gemini-flash-1.5.html

Gbadebo, O. V., Oyewole, A. I., & Adegbayi, O. R. (2022). Sustainable Forest Management Practices: A viable panacea to the challenges of climate change in Nigeria. Proceedings of the 8th Biennial Conference of the Forests and Forest Products Society. https://journals.unizik.edu.ng/index.php/faic/article/download/5526/4581/12581

Google DeepMind. (2024). Gemini 1.5: A technical report on model performance and training efficiency. https://storage.googleapis.com/deepmind-media/gemini/gemini_v1_5_report.pdf

Kalaivani, A., Raj, R. N., & Prakash, T. (2025). A mobile app for the identification of medicinal plants, aiding authenticity and supply chain integrity. Proceedings of the International Conference on Intelligent Systems and Digital Transformation (ICISD 2025). https://www.atlantis-press.com/article/126017035.pdf

Kindwise. (2024). The plant identification battle: GPT-4 vs. Plant.id. Kindwise Botanical Research. https://www.kindwise.com/post/the-plant-identification-battle-gpt-4-vs-plant-id

Long, K., et al. (2023). Plant identification applications do not reliably identify toxic and edible plants in the American Midwest. Clinical Toxicology, 61(7), 524-528. https://pubmed.ncbi.nlm.nih.gov/37535032/

Malik, et al. (2022). Real-time identification of medicinal plants in the natural environment of the Borneo region. FUDMA Journal of Sciences (FJS). https://fjs.fudutsinma.edu.ng/index.php/fjs/article/download/4029/2674/11050

Nwala, P. C., Obute, G. C., & Ekeke, C. (2023). Studies of the indigenous edible wild fruits of Etche Local Government Area, Rivers State, Nigeria. Scientia Africana, 22(3), 65-74. https://pdfs.semanticscholar.org/0e4b/3087406c5c21d7368fb231510dc201fa93c6.pdf

Public Citizen. (2024). Mushrooming Risk: Unreliable A.I. Tools generate mushroom misinformation. Consumer Advocacy Report. https://www.citizen.org/article/mushroom-risk-ai-app-misinformation/

Singh, J. P., Ghosh, D., Kumar, A., Bilgaiyan, S., Kumar, R., & Singh, J. (2026). Hybrid DenseNet architectures and KerasTuner-based optimization for rice leaf disease detection. Research Gate. https://www.researchgate.net/publication/400849955_Hybrid_DenseNet_Architectures_and_KerasTuner-Based_Optimization_for_Rice_Leaf_Disease_Detection

Soni, H. B. (2025). The algorithm of life: How AI is revolutionizing biodiversity and conservation. Biodiversity International Journal, 8(1), 19-31.(https://medcraveonline.com/BIJ/BIJ-08-00217.pdf)

Tadesse, D., Masresha, G., Lulekal, E., & Alemu, A. (2024). Ethnobotanical study of wild edible plants in Metema and Quara districts of north-western Ethiopia. Scientific Reports. https://pmc.ncbi.nlm.nih.gov/articles/PMC11804023/

Umar, M., et al. (2025). Compilation and checklist of medicinal and aromatic plants on Mambilla Plateau in Taraba State, Nigeria. DUJOPAS, 11(1b), 126-131. https://www.ajol.info/index.php/dujopas/article/download/291635/274535

