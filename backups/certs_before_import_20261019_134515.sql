--
-- PostgreSQL database dump
--

\restrict lCftua43fXRwYz13rA7VNmBeaonDDoCBTOi8uLt2GbZLpypXO00M07ntbmcVTRg

-- Dumped from database version 18.6 (Ubuntu 18.6-0ubuntu0.26.04.1)
-- Dumped by pg_dump version 18.6 (Ubuntu 18.6-0ubuntu0.26.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: product_certificate_links; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_certificate_links (
    id integer NOT NULL,
    product_code character varying(50) NOT NULL,
    certificate_id integer NOT NULL,
    link_type character varying(50) DEFAULT 'doc_number_match'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.product_certificate_links OWNER TO postgres;

--
-- Name: product_certificate_links_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_certificate_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_certificate_links_id_seq OWNER TO postgres;

--
-- Name: product_certificate_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_certificate_links_id_seq OWNED BY public.product_certificate_links.id;


--
-- Name: product_certificates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_certificates (
    id integer NOT NULL,
    cert_number character varying(100) NOT NULL,
    doc_number character varying(50),
    cert_date date,
    file_name character varying(255) NOT NULL,
    file_path character varying(500),
    product_info text,
    doc_1c_number character varying(50),
    organization character varying(255),
    product_code character varying(50),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.product_certificates OWNER TO postgres;

--
-- Name: product_certificates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_certificates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_certificates_id_seq OWNER TO postgres;

--
-- Name: product_certificates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_certificates_id_seq OWNED BY public.product_certificates.id;


--
-- Name: product_certificate_links id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_certificate_links ALTER COLUMN id SET DEFAULT nextval('public.product_certificate_links_id_seq'::regclass);


--
-- Name: product_certificates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_certificates ALTER COLUMN id SET DEFAULT nextval('public.product_certificates_id_seq'::regclass);


--
-- Data for Name: product_certificate_links; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_certificate_links (id, product_code, certificate_id, link_type, created_at) FROM stdin;
\.


--
-- Data for Name: product_certificates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_certificates (id, cert_number, doc_number, cert_date, file_name, file_path, product_info, doc_1c_number, organization, product_code, created_at) FROM stdin;
\.


--
-- Name: product_certificate_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_certificate_links_id_seq', 1, false);


--
-- Name: product_certificates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_certificates_id_seq', 1, false);


--
-- Name: product_certificate_links product_certificate_links_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_certificate_links
    ADD CONSTRAINT product_certificate_links_pkey PRIMARY KEY (id);


--
-- Name: product_certificates product_certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_certificates
    ADD CONSTRAINT product_certificates_pkey PRIMARY KEY (id);


--
-- Name: product_certificates uq_cert_number_file; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_certificates
    ADD CONSTRAINT uq_cert_number_file UNIQUE (cert_number, file_name);


--
-- Name: product_certificate_links uq_link_product_cert; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_certificate_links
    ADD CONSTRAINT uq_link_product_cert UNIQUE (product_code, certificate_id);


--
-- Name: idx_certs_cert_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_certs_cert_date ON public.product_certificates USING btree (cert_date);


--
-- Name: idx_certs_cert_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_certs_cert_number ON public.product_certificates USING btree (cert_number);


--
-- Name: idx_certs_doc_1c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_certs_doc_1c ON public.product_certificates USING btree (doc_1c_number);


--
-- Name: idx_certs_product_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_certs_product_code ON public.product_certificates USING btree (product_code);


--
-- Name: idx_certs_product_info; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_certs_product_info ON public.product_certificates USING btree (product_info) WHERE (product_info IS NOT NULL);


--
-- Name: idx_links_cert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_links_cert_id ON public.product_certificate_links USING btree (certificate_id);


--
-- Name: idx_links_product_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_links_product_code ON public.product_certificate_links USING btree (product_code);


--
-- Name: product_certificate_links product_certificate_links_certificate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_certificate_links
    ADD CONSTRAINT product_certificate_links_certificate_id_fkey FOREIGN KEY (certificate_id) REFERENCES public.product_certificates(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict lCftua43fXRwYz13rA7VNmBeaonDDoCBTOi8uLt2GbZLpypXO00M07ntbmcVTRg

