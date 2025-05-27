# Player Similarity in Professional Football Using Unsupervised Learning

This project applies data science techniques to football to identify players with similar performance profiles using unsupervised learning algorithms. The final goal is to support scouting and strategic decision-making in sports management.

## 🎯 Project Summary

A comprehensive tool was developed to detect similarities between football players using performance metrics. The process includes data extraction from public sources, preprocessing, dimensionality reduction (PCA), clustering (K-means), and similarity scoring (cosine and Euclidean). The final insights are delivered via an interactive dashboard in Power BI.

## 📂 Repository Structure

| Folder/File     | Description                                                  |
|-----------------|--------------------------------------------------------------|
| `data/`         | Cleaned datasets in CSV format                               |
| `scripts/`      | R and Python scripts for data extraction and transformation |
| `dashboard/`    | Power BI dashboard file                                      |
| `report/`       | Final report (PDF) explaining the full project               |
| `README.md`     | Project documentation and overview                           |
| `.gitignore`    | Specifies which files/folders Git should ignore              |

## ⚙️ Tools & Technologies

- **R**: Data extraction (`worldfootballR`), PCA, clustering
- **Python**: Data transformation (`pandas`, `numpy`)
- **Power BI**: Dashboard creation
- **FBref** and **Transfermarkt**: Data sources
- **Git & GitHub**: Version control and publication

## 📈 Methodology

1. **Data Extraction**: Using the `worldfootballR` package in R from FBref and Transfermarkt.
2. **Data Cleaning & Transformation**: Performed in Python and Excel.
3. **Dimensionality Reduction**: PCA applied per player position.
4. **Clustering**: K-means used to segment players by style and characteristics.
5. **Similarity Scores**: Cosine and Euclidean distances used to compare players.
6. **Dashboard**: Built in Power BI to explore similarities interactively.

## 📊 Use Cases

- Identify replacements for a transferred or injured player.
- Discover hidden talents in less-known leagues.
- Compare young prospects with top-level players.
- Support tactical analysis and player repositioning.

## 🖼️ Sample Output

Examples of similarity comparisons, PCA visualizations, and player clusters are included in the final report and Power BI dashboard.

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

Luis Rodríguez Rico  
June 2023 – Final Master's Project
