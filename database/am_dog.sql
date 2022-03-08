--
-- PostgreSQL database dump
--

-- Dumped from database version 12.9
-- Dumped by pg_dump version 12.9

-- Started on 2022-03-15 14:19:36 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 19 (class 2615 OID 22311)
-- Name: am_dog; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA am_dog;


ALTER SCHEMA am_dog OWNER TO postgres;

SET default_table_access_method = heap;

--
-- TOC entry 289 (class 1259 OID 22312)
-- Name: analyses; Type: TABLE; Schema: am_dog; Owner: postgres
--

CREATE TABLE am_dog.analyses (
    analysis_no integer NOT NULL,
    project_no integer NOT NULL,
    analysis_name character varying(40) NOT NULL,
    max_block_length numeric(5,0) NOT NULL,
    analysis_description character varying(400),
    max_score numeric(5,0),
    homogeneity_required boolean,
    lower_limit numeric(5,0),
    date timestamp without time zone,
    exclusion_length numeric(6,0),
    completed boolean DEFAULT false,
    archived date,
    deleted date,
    autozygosity_required boolean
);


ALTER TABLE am_dog.analyses OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 22316)
-- Name: chips; Type: TABLE; Schema: am_dog; Owner: postgres
--

CREATE TABLE am_dog.chips (
    chip_no smallint NOT NULL,
    chip_name character varying(100) NOT NULL,
    manufacturer character varying(100),
    do_not_use boolean
);


ALTER TABLE am_dog.chips OWNER TO postgres;

--
-- TOC entry 354 (class 1259 OID 24775)
-- Name: marker_alleles; Type: TABLE; Schema: am_dog; Owner: postgres
--

CREATE TABLE am_dog.marker_alleles (
    chip_no smallint NOT NULL,
    marker_id text NOT NULL,
    chromosome smallint NOT NULL,
    "position" integer NOT NULL,
    allele_a character(1) NOT NULL,
    allele_b character(1) NOT NULL
);


ALTER TABLE am_dog.marker_alleles OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 22319)
-- Name: markers; Type: TABLE; Schema: am_dog; Owner: postgres
--

CREATE TABLE am_dog.markers (
    dbsnp_no numeric(8,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0)
);


ALTER TABLE am_dog.markers OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 22322)
-- Name: markers2chips; Type: TABLE; Schema: am_dog; Owner: postgres
--

CREATE TABLE am_dog.markers2chips (
    chip_no smallint,
    dbsnp_no integer,
    marker_name character varying(100) NOT NULL,
    remarks character varying(100)
);


ALTER TABLE am_dog.markers2chips OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 22325)
-- Name: projects; Type: TABLE; Schema: am_dog; Owner: postgres
--

CREATE TABLE am_dog.projects (
    project_no integer NOT NULL,
    project_name character varying(40) NOT NULL,
    user_login character varying(20) NOT NULL,
    access_restricted boolean DEFAULT true,
    marker_count integer,
    unique_id character varying(30),
    creation_date date,
    vcf_build smallint,
    completed boolean DEFAULT false,
    deleted date,
    archived date,
    genotypes_count integer
);


ALTER TABLE am_dog.projects OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 22330)
-- Name: projects_permissions; Type: TABLE; Schema: am_dog; Owner: postgres
--

CREATE TABLE am_dog.projects_permissions (
    project_no integer NOT NULL,
    user_login character varying(20) NOT NULL,
    analyse_data boolean NOT NULL,
    query_data boolean NOT NULL
);


ALTER TABLE am_dog.projects_permissions OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 22333)
-- Name: sequence_analyses; Type: SEQUENCE; Schema: am_dog; Owner: postgres
--

CREATE SEQUENCE am_dog.sequence_analyses
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am_dog.sequence_analyses OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 22335)
-- Name: sequence_projects; Type: SEQUENCE; Schema: am_dog; Owner: postgres
--

CREATE SEQUENCE am_dog.sequence_projects
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am_dog.sequence_projects OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 22337)
-- Name: variants; Type: TABLE; Schema: am_dog; Owner: postgres
--

CREATE TABLE am_dog.variants (
    marker_no numeric(10,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0) NOT NULL,
    source character(1)
);


ALTER TABLE am_dog.variants OWNER TO postgres;

--
-- TOC entry 271563 (class 2606 OID 22341)
-- Name: analyses am_dogs_analyses_analysis_name_unique; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.analyses
    ADD CONSTRAINT am_dogs_analyses_analysis_name_unique UNIQUE (project_no, analysis_name);


--
-- TOC entry 271566 (class 2606 OID 22345)
-- Name: analyses pk_am_dog_analyses; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.analyses
    ADD CONSTRAINT pk_am_dog_analyses PRIMARY KEY (analysis_no);


--
-- TOC entry 271568 (class 2606 OID 22347)
-- Name: chips pk_am_dog_chips; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.chips
    ADD CONSTRAINT pk_am_dog_chips PRIMARY KEY (chip_no);


--
-- TOC entry 271573 (class 2606 OID 22349)
-- Name: markers pk_am_dog_markers; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.markers
    ADD CONSTRAINT pk_am_dog_markers PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271579 (class 2606 OID 22351)
-- Name: projects pk_am_dog_projects; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.projects
    ADD CONSTRAINT pk_am_dog_projects PRIMARY KEY (project_no);


--
-- TOC entry 271585 (class 2606 OID 22353)
-- Name: projects_permissions pk_am_dog_projects_permissions; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.projects_permissions
    ADD CONSTRAINT pk_am_dog_projects_permissions PRIMARY KEY (project_no, user_login);


--
-- TOC entry 271589 (class 2606 OID 22343)
-- Name: variants pk_dogvariants; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.variants
    ADD CONSTRAINT pk_dogvariants PRIMARY KEY (marker_no);


--
-- TOC entry 271581 (class 2606 OID 22355)
-- Name: projects projects_unique_id_key; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.projects
    ADD CONSTRAINT projects_unique_id_key UNIQUE (unique_id);


--
-- TOC entry 271570 (class 2606 OID 22357)
-- Name: chips u_am_dog_chips_chip_name; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.chips
    ADD CONSTRAINT u_am_dog_chips_chip_name UNIQUE (chip_name);


--
-- TOC entry 271577 (class 2606 OID 22359)
-- Name: markers2chips u_am_dog_markers2chips_marker_name; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.markers2chips
    ADD CONSTRAINT u_am_dog_markers2chips_marker_name UNIQUE (marker_name, chip_no);


--
-- TOC entry 271583 (class 2606 OID 22361)
-- Name: projects u_am_dog_projects_project_name; Type: CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.projects
    ADD CONSTRAINT u_am_dog_projects_project_name UNIQUE (project_name);


--
-- TOC entry 271564 (class 1259 OID 22362)
-- Name: fki_am_dog_analyses_project_no; Type: INDEX; Schema: am_dog; Owner: postgres
--

CREATE INDEX fki_am_dog_analyses_project_no ON am_dog.analyses USING btree (project_no);


--
-- TOC entry 271574 (class 1259 OID 22365)
-- Name: i_am_dog_markers2chips_chip_no; Type: INDEX; Schema: am_dog; Owner: postgres
--

CREATE INDEX i_am_dog_markers2chips_chip_no ON am_dog.markers2chips USING btree (chip_no);


--
-- TOC entry 271575 (class 1259 OID 22366)
-- Name: i_am_dog_markers2chips_marker_no; Type: INDEX; Schema: am_dog; Owner: postgres
--

CREATE INDEX i_am_dog_markers2chips_marker_no ON am_dog.markers2chips USING btree (dbsnp_no);


--
-- TOC entry 271571 (class 1259 OID 22367)
-- Name: i_am_dog_markers_chromosome_position; Type: INDEX; Schema: am_dog; Owner: postgres
--

CREATE INDEX i_am_dog_markers_chromosome_position ON am_dog.markers USING btree (chromosome, "position");


--
-- TOC entry 271586 (class 1259 OID 22363)
-- Name: i_dogvariants_chromosome_position; Type: INDEX; Schema: am_dog; Owner: postgres
--

CREATE INDEX i_dogvariants_chromosome_position ON am_dog.variants USING btree (chromosome, "position");


--
-- TOC entry 271587 (class 1259 OID 22364)
-- Name: i_dogvariants_source; Type: INDEX; Schema: am_dog; Owner: postgres
--

CREATE INDEX i_dogvariants_source ON am_dog.variants USING btree (source);


--
-- TOC entry 271590 (class 2606 OID 22368)
-- Name: analyses fk_am_dog_analyses_project_no; Type: FK CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.analyses
    ADD CONSTRAINT fk_am_dog_analyses_project_no FOREIGN KEY (project_no) REFERENCES am_dog.projects(project_no);


--
-- TOC entry 271591 (class 2606 OID 22373)
-- Name: markers2chips fk_am_dog_markers2chips_2_chips; Type: FK CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.markers2chips
    ADD CONSTRAINT fk_am_dog_markers2chips_2_chips FOREIGN KEY (chip_no) REFERENCES am_dog.chips(chip_no);


--
-- TOC entry 271592 (class 2606 OID 22378)
-- Name: markers2chips fk_am_dog_markers2chips_2_markers; Type: FK CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.markers2chips
    ADD CONSTRAINT fk_am_dog_markers2chips_2_markers FOREIGN KEY (dbsnp_no) REFERENCES am_dog.markers(dbsnp_no);


--
-- TOC entry 271593 (class 2606 OID 22383)
-- Name: projects_permissions fk_am_dog_projects_permissions_2_projects; Type: FK CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.projects_permissions
    ADD CONSTRAINT fk_am_dog_projects_permissions_2_projects FOREIGN KEY (project_no) REFERENCES am_dog.projects(project_no);


--
-- TOC entry 271594 (class 2606 OID 26299)
-- Name: projects_permissions fk_projects_permissions_2_project; Type: FK CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.projects_permissions
    ADD CONSTRAINT fk_projects_permissions_2_project FOREIGN KEY (user_login) REFERENCES am.users(user_login);


--
-- TOC entry 271595 (class 2606 OID 24781)
-- Name: marker_alleles marker_alleles_chip_no_fkey; Type: FK CONSTRAINT; Schema: am_dog; Owner: postgres
--

ALTER TABLE ONLY am_dog.marker_alleles
    ADD CONSTRAINT marker_alleles_chip_no_fkey FOREIGN KEY (chip_no) REFERENCES am_dog.chips(chip_no);


--
-- TOC entry 271727 (class 0 OID 0)
-- Dependencies: 19
-- Name: SCHEMA am_dog; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA am_dog TO PUBLIC;


--
-- TOC entry 271728 (class 0 OID 0)
-- Dependencies: 289
-- Name: TABLE analyses; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_dog.analyses TO PUBLIC;


--
-- TOC entry 271729 (class 0 OID 0)
-- Dependencies: 290
-- Name: TABLE chips; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_dog.chips TO PUBLIC;


--
-- TOC entry 271730 (class 0 OID 0)
-- Dependencies: 354
-- Name: TABLE marker_alleles; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT ALL ON TABLE am_dog.marker_alleles TO genetik;


--
-- TOC entry 271731 (class 0 OID 0)
-- Dependencies: 291
-- Name: TABLE markers; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_dog.markers TO PUBLIC;


--
-- TOC entry 271732 (class 0 OID 0)
-- Dependencies: 292
-- Name: TABLE markers2chips; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_dog.markers2chips TO PUBLIC;


--
-- TOC entry 271733 (class 0 OID 0)
-- Dependencies: 293
-- Name: TABLE projects; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_dog.projects TO PUBLIC;


--
-- TOC entry 271734 (class 0 OID 0)
-- Dependencies: 294
-- Name: TABLE projects_permissions; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_dog.projects_permissions TO PUBLIC;


--
-- TOC entry 271735 (class 0 OID 0)
-- Dependencies: 295
-- Name: SEQUENCE sequence_analyses; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT ALL ON SEQUENCE am_dog.sequence_analyses TO genetik;
GRANT ALL ON SEQUENCE am_dog.sequence_analyses TO PUBLIC;


--
-- TOC entry 271736 (class 0 OID 0)
-- Dependencies: 296
-- Name: SEQUENCE sequence_projects; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT ALL ON SEQUENCE am_dog.sequence_projects TO genetik;
GRANT ALL ON SEQUENCE am_dog.sequence_projects TO PUBLIC;


--
-- TOC entry 271737 (class 0 OID 0)
-- Dependencies: 297
-- Name: TABLE variants; Type: ACL; Schema: am_dog; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_dog.variants TO PUBLIC;
GRANT ALL ON TABLE am_dog.variants TO genetik;


-- Completed on 2022-03-15 14:19:43 CET

--
-- PostgreSQL database dump complete
--

