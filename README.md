
# ⚽ Player Similarity Analysis Using Unsupervised Learning

This project applies data analytics and unsupervised machine learning techniques to identify similar football players based on their performance metrics. The methodology includes dimensionality reduction (PCA), clustering (K-means), and similarity measures (cosine and Euclidean distances). The results are visualized through an interactive dashboard built in Power BI.

---

## 🎯 Project Objectives

- Group players based on performance characteristics using clustering.
- Reduce dimensionality with PCA for clearer visualizations and analysis.
- Calculate player similarity using cosine and Euclidean distances.
- Build an interactive dashboard in Power BI for user-friendly exploration.

---

## 📁 Repository Structure

| Folder/File       | Description                                      |
|-------------------|--------------------------------------------------|
| `data/raw/`       | Unprocessed (original) datasets                  |
| `data/processed/` | Cleaned and transformed datasets                 |
| `scripts/`        | R and Python scripts for data processing         |
| `dashboard/`      | Power BI dashboard file (`.pbix`)                |
| `report/`         | Final report in PDF format                       |
| `requirements/`   | Auxiliary Excel file used during the dataset construction |
| `README.md`       | Project documentation                            |
| `.gitignore`      | Git exclusion rules                              |

> Note: The `raw/` and `processed/` folders are placeholders for organizing datasets by their processing stage.

---

## 🛠️ Tools & Technologies

- **Languages:** Python, R
- **Libraries:** pandas, scikit-learn, tidyverse, factoextra
- **Visualization:** Power BI
- **Version Control:** Git, GitHub
- **Large File Support:** Git LFS (for `.pbix` files)

---

## 📊 Interactive Dashboard

The Power BI dashboard includes:

- Visual representation of clustered player groups
- Player comparison based on selected metrics
- Searchable interface for exploring individual profiles

> ⚠️ Due to GitHub’s file size limits, the `.pbix` file is not directly included in this repository. You can access the dashboard here:

[🔗 View Interactive Dashboard](https://app.powerbi.com/view?r=eyJrIjoiOWI3OTdlZjctYmQ0MC00MWNlLTkzM2YtMmE4MWNmZDhhZjI2IiwidCI6IjA1ZWE3NGEzLTkyYzUtNGMzMS05NzhhLTkyNWMzYzc5OWNkMCIsImMiOjh9)


---

## 📄 Final Report

The final PDF report includes:

- Data sources and preprocessing
- Methodology for PCA and clustering
- Interpretation of results
- Applications and conclusions

> 📥 [Download Final Report](report/Report.pdf)
> 📥 [Download Final Presentation (Spanish)](report/Presentation.pptx)

---

## 🚀 Getting Started

1. **Clone the repository:**

   ```bash
   git clone https://github.com/lrbusto/football-player-similarity.git
   cd football-player-similarity
   ```

2. **Install dependencies:**

   - Python:

     ```bash
     pip install -r requirements.txt
     ```

   - R:

     ```R
     install.packages(c("tidyverse", "cluster", "factoextra"))
     ```

3. **Explore the scripts:**

   - `Extract.R`: Gets data from the different portals and APIs
   - `scripts/Transform.py`: Cleans and formats the data
   - `scripts/Unsupervised_Analysis.R`: Performs PCA and clustering

4. **Visualize the dashboard:**

   - Open the `.pbix` file with Power BI Desktop
   - Or use the public dashboard link above

---

## 📌 Notes

- **Data Sources:** FBref and Transfermarkt (public football statistics)
- **Privacy:** No personal or sensitive data is included
- **License:** MIT License

---

## 🤝 Contributions

Contributions are welcome! If you'd like to improve the project:

1. Fork the repo
2. Create a new branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to your branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## 📬 Contact

**Luis Rodríguez Rico**  
📧 [luisrguezrico97@gmail.com](mailto:luisrguezrico97@gmail.com)  
💼 [LinkedIn](https://www.linkedin.com/in/luis-rodr%C3%ADguez-rico-a9241b134/)
