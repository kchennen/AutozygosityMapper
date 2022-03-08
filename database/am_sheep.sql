--
-- PostgreSQL database dump
--

-- Dumped from database version 12.9
-- Dumped by pg_dump version 12.9

-- Started on 2022-03-15 14:20:46 CET

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
-- TOC entry 18 (class 2615 OID 24808)
-- Name: am_sheep; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA am_sheep;


ALTER SCHEMA am_sheep OWNER TO postgres;

SET default_table_access_method = heap;

--
-- TOC entry 358 (class 1259 OID 24826)
-- Name: analyses; Type: TABLE; Schema: am_sheep; Owner: postgres
--

CREATE TABLE am_sheep.analyses (
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


ALTER TABLE am_sheep.analyses OWNER TO postgres;

--
-- TOC entry 359 (class 1259 OID 24840)
-- Name: chips; Type: TABLE; Schema: am_sheep; Owner: postgres
--

CREATE TABLE am_sheep.chips (
    chip_no smallint NOT NULL,
    chip_name character varying(100) NOT NULL,
    manufacturer character varying(100),
    do_not_use boolean
);


ALTER TABLE am_sheep.chips OWNER TO postgres;

--
-- TOC entry 360 (class 1259 OID 24847)
-- Name: marker_alleles; Type: TABLE; Schema: am_sheep; Owner: postgres
--

CREATE TABLE am_sheep.marker_alleles (
    chip_no smallint NOT NULL,
    marker_id text NOT NULL,
    chromosome smallint NOT NULL,
    "position" integer NOT NULL,
    allele_a character(1) NOT NULL,
    allele_b character(1) NOT NULL
);


ALTER TABLE am_sheep.marker_alleles OWNER TO postgres;

--
-- TOC entry 357 (class 1259 OID 24815)
-- Name: projects; Type: TABLE; Schema: am_sheep; Owner: postgres
--

CREATE TABLE am_sheep.projects (
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


ALTER TABLE am_sheep.projects OWNER TO postgres;

--
-- TOC entry 361 (class 1259 OID 24858)
-- Name: projects_permissions; Type: TABLE; Schema: am_sheep; Owner: postgres
--

CREATE TABLE am_sheep.projects_permissions (
    project_no integer NOT NULL,
    user_login character varying(20) NOT NULL,
    analyse_data boolean NOT NULL,
    query_data boolean NOT NULL
);


ALTER TABLE am_sheep.projects_permissions OWNER TO postgres;

--
-- TOC entry 271566 (class 2606 OID 24833)
-- Name: analyses am_sheeps_analyses_analysis_name_unique; Type: CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.analyses
    ADD CONSTRAINT am_sheeps_analyses_analysis_name_unique UNIQUE (project_no, analysis_name);


--
-- TOC entry 271569 (class 2606 OID 24831)
-- Name: analyses pk_am_sheep_analyses; Type: CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.analyses
    ADD CONSTRAINT pk_am_sheep_analyses PRIMARY KEY (analysis_no);


--
-- TOC entry 271571 (class 2606 OID 24844)
-- Name: chips pk_am_sheep_chips; Type: CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.chips
    ADD CONSTRAINT pk_am_sheep_chips PRIMARY KEY (chip_no);


--
-- TOC entry 271560 (class 2606 OID 24821)
-- Name: projects pk_am_sheep_projects; Type: CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.projects
    ADD CONSTRAINT pk_am_sheep_projects PRIMARY KEY (project_no);


--
-- TOC entry 271575 (class 2606 OID 24862)
-- Name: projects_permissions pk_am_sheep_projects_permissions; Type: CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.projects_permissions
    ADD CONSTRAINT pk_am_sheep_projects_permissions PRIMARY KEY (project_no, user_login);


--
-- TOC entry 271562 (class 2606 OID 24823)
-- Name: projects projects_unique_id_key; Type: CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.projects
    ADD CONSTRAINT projects_unique_id_key UNIQUE (unique_id);


--
-- TOC entry 271573 (class 2606 OID 24846)
-- Name: chips u_am_sheep_chips_chip_name; Type: CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.chips
    ADD CONSTRAINT u_am_sheep_chips_chip_name UNIQUE (chip_name);


--
-- TOC entry 271564 (class 2606 OID 24825)
-- Name: projects u_am_sheep_projects_project_name; Type: CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.projects
    ADD CONSTRAINT u_am_sheep_projects_project_name UNIQUE (project_name);


--
-- TOC entry 271567 (class 1259 OID 24839)
-- Name: fki_am_sheep_analyses_project_no; Type: INDEX; Schema: am_sheep; Owner: postgres
--

CREATE INDEX fki_am_sheep_analyses_project_no ON am_sheep.analyses USING btree (project_no);


--
-- TOC entry 271576 (class 2606 OID 24834)
-- Name: analyses fk_am_sheep_analyses_project_no; Type: FK CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.analyses
    ADD CONSTRAINT fk_am_sheep_analyses_project_no FOREIGN KEY (project_no) REFERENCES am_sheep.projects(project_no);


--
-- TOC entry 271578 (class 2606 OID 24863)
-- Name: projects_permissions fk_am_sheep_projects_permissions_2_projects; Type: FK CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.projects_permissions
    ADD CONSTRAINT fk_am_sheep_projects_permissions_2_projects FOREIGN KEY (project_no) REFERENCES am_sheep.projects(project_no);


--
-- TOC entry 271579 (class 2606 OID 26319)
-- Name: projects_permissions fk_projects_permissions_2_project; Type: FK CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.projects_permissions
    ADD CONSTRAINT fk_projects_permissions_2_project FOREIGN KEY (user_login) REFERENCES am.users(user_login);


--
-- TOC entry 271577 (class 2606 OID 24853)
-- Name: marker_alleles marker_alleles_chip_no_fkey; Type: FK CONSTRAINT; Schema: am_sheep; Owner: postgres
--

ALTER TABLE ONLY am_sheep.marker_alleles
    ADD CONSTRAINT marker_alleles_chip_no_fkey FOREIGN KEY (chip_no) REFERENCES am_sheep.chips(chip_no);


--
-- TOC entry 271711 (class 0 OID 0)
-- Dependencies: 18
-- Name: SCHEMA am_sheep; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA am_sheep TO genetik;


--
-- TOC entry 271712 (class 0 OID 0)
-- Dependencies: 358
-- Name: TABLE analyses; Type: ACL; Schema: am_sheep; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_sheep.analyses TO PUBLIC;


--
-- TOC entry 271713 (class 0 OID 0)
-- Dependencies: 359
-- Name: TABLE chips; Type: ACL; Schema: am_sheep; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_sheep.chips TO PUBLIC;


--
-- TOC entry 271714 (class 0 OID 0)
-- Dependencies: 360
-- Name: TABLE marker_alleles; Type: ACL; Schema: am_sheep; Owner: postgres
--

GRANT ALL ON TABLE am_sheep.marker_alleles TO genetik;


--
-- TOC entry 271715 (class 0 OID 0)
-- Dependencies: 357
-- Name: TABLE projects; Type: ACL; Schema: am_sheep; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_sheep.projects TO PUBLIC;


--
-- TOC entry 271716 (class 0 OID 0)
-- Dependencies: 361
-- Name: TABLE projects_permissions; Type: ACL; Schema: am_sheep; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE am_sheep.projects_permissions TO PUBLIC;


-- Completed on 2022-03-15 14:20:53 CET

--
-- PostgreSQL database dump complete
--

