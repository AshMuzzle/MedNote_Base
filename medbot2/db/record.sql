-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: database:3306
-- Generation Time: Jul 08, 2023 at 05:46 PM
-- Server version: 8.0.33
-- PHP Version: 8.1.17
/*
Name: [Patient's Full Name] --MAPPED TO patient {f_name, m_name l_name}     
Date of Birth: [DOB] --MAPPED TO patient {birth_date}
Date of Visit: [Date] --MAPPED TO appointment {visit_date}
Provider: [Provider's Name] --MAPPED TO patient {provider}
Chief Complaint: MAPPED TO appointment {chief_complaint}
 
[Summarize the patient’s primary concern or reason for the visit.]
 
History of Present Illness (HPI):
 
Onset: [When did the symptoms start?]
Duration: [How long have the symptoms been present?]
Location: [Where are the symptoms located?]
Severity: [Describe the severity of the symptoms.]
Characteristics: [Describe the nature or type of symptoms.]
Aggravating Factors: [What factors worsen the symptoms?]
Relieving Factors: [What factors relieve the symptoms?]
Physical Examination:
 
Vital Signs: [Record any vital signs mentioned in the conversation.]
General Appearance: [Describe the patient's overall appearance if relevant.]
Relevant Findings: [Summarize key physical exam findings.]
Assessment and Plan:
 
Diagnosis: [Provide the primary diagnosis or differential diagnoses.]
Plan: [Outline the treatment plan, including any further tests, referrals, or interventions.]
Patient Education: [Summarize any patient education or advice given.]
Follow-Up:
 
Instructions: [Provide instructions for follow-up or next steps.]
Signature:
 
Provider’s Name: [Provider's Name]
Date: [Date]

*/


/* Creation database tables was implemented.
 No further functionality was added as this was scrapped later in the project*/
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `todo_app`
--

-- --------------------------------------------------------


CREATE TABLE `patient` (
  `p_id` int NOT NULL, --id of patient
  `f_name` varchar(20), --first name of patient
  `m_name` varchar(20), --middle name of patient
  `l_name` varchar(20) NOT NULL, --last name of patient
  `provider` varchar(50) NOT NULL, --name of patients HC provider
  `birth_date` Date NOT NULL --Date of patients birth
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `appointment` (
  `a_id` int NOT NULL, --id of appointment
  `p_id` int NOT NULL, --id of patient associated with appointment
  `visit_date` DateTime NOT NULL, --Date of patients visit
  `onset` DateTime, --Symptoms estimated start date and time.
  `concern_summary` text, --Summary of the patients primary concern or reason for the visit
  `chief_complaint`varchar(55), --Doctors main concern(s) about meeting
  `plan` text, --Outline of the treatment plan, including any further tests, referrals, or interventions.
  `pat_education` int, --Summary of any patient education or advice given.
  `signature` int, --id of symptom
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `symptoms` (
    `s_id` int NOT NULL, --id of symptom
    'a_id' int, --id of appointment
    `name` varchar(25) NOT NULL --symptom patient is experiencing
    `duration` DateTime, --how long symptoms have been present
    `location` varchar(20), --Where were the symptoms located?
    `severity` varchar(8), --High, medium, low. 

)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `diagnosis` (
    `d_id` int NOT NULL, --id of diagnosis
    `d_name` int NOT NULL, --name of the diagnosis
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;