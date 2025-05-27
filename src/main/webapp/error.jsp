<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Error - Heeyaichen's Portfolio</title>

        <!-- Font Awesome from WebJars -->
        <link rel="stylesheet" href="webjars/font-awesome/6.4.0/css/all.min.css">
        <!-- Google Fonts -->
        <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600;700&display=swap"
            rel="stylesheet">
        <!-- Custom CSS -->
        <link rel="stylesheet" href="css/styles.css">
        <style>
            .error-card {
                background-color: var(--card-background);
                border-radius: 15px;
                box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
                padding: 40px;
                text-align: center;
                margin: 0 auto;
                max-width: 600px;
            }

            .error-icon {
                font-size: 4rem;
                color: #e74c3c;
                margin-bottom: 20px;
            }

            .error-card h1 {
                margin-bottom: 20px;
            }

            .error-card p {
                margin-bottom: 30px;
                opacity: 0.8;
            }

            .error-btn {
                display: inline-block;
                background: var(--accent-color);
                color: var(--text-color);
                padding: 12px 24px;
                border-radius: 30px;
                text-decoration: none;
                font-weight: 600;
                transition: all 0.3s ease;
            }

            .error-btn:hover {
                background: var(--hover-color);
                transform: translateY(-2px);
            }
        </style>
    </head>

    <body>
        <div class="container">
            <div class="error-card">
                <i class="fas fa-exclamation-circle error-icon"></i>
                <h1>Oops! Something went wrong</h1>
                <p>We're sorry for the inconvenience. Please try again later or return to the homepage.</p>
                <a href="index.jsp" class="error-btn">
                    <i class="fas fa-home me-2"></i> Return Home
                </a>
            </div>
        </div>
    </body>

    </html>